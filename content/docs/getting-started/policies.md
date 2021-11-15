+++
title = "Authorization policies"
description = "How Datalog policies work"
date = 2021-05-01T08:20:00+00:00
updated = 2021-05-01T08:20:00+00:00
draft = false
weight = 20
sort_by = "weight"
template = "docs/page.html"

[extra]
lead = "How Datalog policies work"
toc = true
top = false
+++

## Datalog authorization policies

A Biscuit token could be verified by applications in various languages. To make sure that authorization policies are interpreted the same way everywhere, and to avoid brittle solutions based on custom parsers of text fields, Biscuit specifies an authorization language inspired from [Datalog](https://en.wikipedia.org/wiki/Datalog), that must be parsed and executed identically by every implementation.

Logic languages are well suited for authorization policies, because they can represent complex relations between elements (like roles, groups, hierarchies) concisely, and efficiently explore and combine multiple rules.

Biscuit's language loads facts, data that can come from the token (example: user id), from the request (file name, read or write access, current date) or the application's internal databases (users, roles, rights).
Then it validates those facts in two ways:
- a check list: each check validates the presence of a fact. Example: `check if time($current_time), $time < 2022-01-01T00:00:00Z` for an expiration date. If at least one of the checks fails, the request is denied
- allow/deny policies: a list of poliies that are tried in sequence until one of them matches. If it is an allow policy, the request is accepted, while if it is a deny policy or none matched, the request is denied. Example: `allow if resource($res), operation($op), right($res, $op)`

Allow/deny policies can only be defined in the application, while checks can come from the application or the token. This is how token are attenuated: by adding more checks (ie more restrictions) to an existing token.


## First code example

<div class="text-left">
{% datalog() %}
resource("file1.txt");
check if resource($file), $file.ends_with("txt");
allow if true;
{% end %}
</div>

# Datalog in Biscuit

Biscuit comes with a few specific adaptations of Datalog.

It has the following base types (for elements inside of a fact):

- integer (i64)
- string
- date (seconds from epoch, UTC)
- byte array
- symbol (interned strings that are stored in a dictionary to spare space)
- boolean (true or false)
- set: a deduplicated list of values, that can be of any type except variables or sets

Rules can contain expressions that evaluate variable defined in the other
predicates. An expression must always evaluate to a boolean. If it returns
false, the rule evaluation fails. The following rule will generate a fact only
if there's a `file` fact and its value starts with `/folder/`:

`in_folder($path) <- file($path), $path.starts_with(/folder/*)`

Here are the possible operations:

- integer: <, >, <=, >=, ==, +, -, *, /
- string: .starts_with(string), .ends_with(string), .matches(regex string), ==
- date: <=, >=
- byte array: ==, is in set, is not in set
- boolean: &&,  ||, !
- set: .contains(value)

## Checks

The first part of the authorization logic comes with _checks_: they are queries over
the Datalog facts. If the query produces something, (if the underlying rule
generates one or more facts), the check is validated, if it does not, the
check fails. For a token verification to be successful, all of the checks
must succeed.

As an example, we could have a check that tests the presence of a file
resource, and verifies that its filename matches a specific pattern,
using a string expression:

```
check if
  resource(#ambient, $path),
  $path.matches("file[0-9]+.txt")
```

This check matches only if there exists a `resource(#ambient, $path)` fact for
which `$path` matches a pattern.

## `#ambient` and `#authority` symbols

This check uses a _symbol_ named `#ambient` (symbols start with a `#`).

There are two special symbols that can appear in facts:

-`#ambient`: facts that are _provided by the verifier_, and that depend on the **request**, like which resource we want to access(file path, REST endpoint, etc), operation(read, write...), current date and time, source IP address, HTTP headers...
- `#authority`: facts _defined by the token's original creator_ or _the verifier_, that indicates the basic rights of the **token**. Every new attenation of the token will reduce those rights by adding checks

`#ambient` and `#authority` tokens can only be provided by the token's origin
or by the verifier, **they cannot be added by attenuating the token**.

## Allow and deny policies

The validation in Biscuit relies on a list of allow or deny policies, that are
evaluated after all of the checks have succeeded. Like checks; they are queries
that must find a matching set of fact to succeed. If they do not match, we try
the next one. If they succeed, an allow policy will make the request validation
succeed, while a deny policy will make it fail. If no policy matched, the
validation will fail.

Example policies:

```
// verifies that we have rights for this request
allow if
  resource(#ambient, $res),
  operation(#ambient, $op),
  right(#authority, $res, $op)

// otherwise, allow if we're admin
allow if is_admin(#authority)

// catch all if non of the policies matched
deny if true
```

##### Revocation identifiers

The verifier will generate a list of facts indicating revocation identifiers for
the token. They uniquely identify the token and each of its parent tokens through
a serie of SHA256 hashes. That way, if a token is revoked, we will be able to
refuse all the tokens derived from it.

To check revocation status, we can either:
- query the list of revocation tokens: `revocation($index, $id) <- revocation_id($index, $id)` then verify their presence in a revocation list
- load a policy with the list of revoked tokens: `deny if revocation_id($index, $id), [ hex:1234..., hex:4567...].contains($id)`

The hashes are generated from the serialized blocks and the corresponding keys,
so if you generate multiple tokens with the same root key and same authority
block, they will have the same revocation identifier. To avoid that, you can
add unique data to the block, like a random value, a UUID identifying that
token chain, a date, etc.

# Example tokens

Let's make an example, from an S3-like application, on which we can store and
retrieve files, with users having access to "buckets" holding a list of files.

Here is a first example token, that will hold a user id. This token only
contains one block, that has been signed with the root private key. The
verifier's side knows the root public key and, upon receiving the request,
will deserialize the token and verify its signature, thus authenticating
the token.

```
Biscuit {
    symbols: ["authority", "ambient", "resource", "operation", "right", "current_time", "revocation_id", "user_id"]
    authority: Block[0] {
            symbols: ["user_id"]
            context: ""
            version: 1
            facts: [
                user_id(#authority, "user_1234"),
            ]
            rules: []
            checks: []
        }
    blocks: [
    ]
}
```

Let's unpack what's displayed here:

 - `symbols` carries a list of symbols used in the biscuit.
 - `authority` carries information provided by the token creator. It gives the initial scope of the bicuit.
 - `blocks` carries a list of blocks, which can refine the scope of the biscuit

Here, `authority` provides the initial block, which can be refined in subsequent blocks.

A block comes with new symbols it adds to the system (there's a default symbol
table that already contains values like `#authority` or `#operation`). It can
contain facts, rules and checks. A block contains:

 - `symbols`:  a block can introduce new symbols: these symbols are available in the current block, _and the following blocks_. **It is not possible to re-declare an existing symbol**.
 - `context`: free form text used either for documentation purpose, or to give a hind about which facts should be retrieved from DB
 - `facts`: each block can define new facts (but only `authority` can define facts mentioning `#authority`)
 - `rules` each block can define new rules (but only `authority` can define rules deriving facts mentioning `#authority`)
 - `checks` each block can define new checks (queries that need to match in order to make the biscuit valid)

Let's assume the user is sending this token with a `PUT /bucket_5678/folder1/hello.txt` HTTP
request. The verifier would then load the token's facts and rules, along with
facts from the request:

```
user_id(#authority, "user_1234");
operation(#ambient, #write);
resource(#ambient, "bucket_5678", "/folder1/hello.txt");
current_time(#ambient, 2020-11-17T12:00:00+00:00);
```

The verifier would also be able to load authorization data from its database,
like ownership information: `owner(#authority, "user_1234", "bucket_1234")`,
`owner(#authority, "user_1234", "bucket_5678")` `owner(#authority, "user_ABCD", "bucket_ABCD")`.
In practice,this data could be filtered by limiting it to facts related to
the current ressource, or extracting the user id from the token with a query.

The verifier can also load its own rules, like creating one specifying rights
if we own a specific folder:

```
// the resource owner has all rights on the resource
right(#authority, $bucket, $path, $operation) <-
  resource(#ambient, $bucket, $path),
  operation(#ambient, $operation),
  user_id(#authority, $id),
  owner(#authority, $id, $bucket)
```

This rule will generate a `right` fact if it finds data matching the variables.

We end up with a system with the following facts:

```
user_id(#authority, "user_1234");
operation(#ambient, #write);
resource(#ambient, "bucket_5678", "/folder1/hello.txt");
current_time(#ambient, 2020-11-17T12:00:00+00:00);
owner(#authority, "user_1234", "bucket_1234");
owner(#authority, "user_1234", "bucket_5678");
owner(#authority, "user_ABCD", "bucket_ABCD");
right(#authority, "bucket_5678", "/folder1/hello.txt", #write);
```

At last, the verifier provides a policy to test that we have the rights for this
operation:

```
allow if
  right(#authority, $bucket, $path, $operation),
  resource(#ambient, $bucket, $path),
  operation(#ambient, $operation)
```

Here we can find matching facts, so the request succeeds. If the request was
done on `bucket_ABCD`, we would not be able to generate the `right` fact for
it and the request would fail.

Now, what if we wanted to limit access to reading `/folder1/hello.txt` in
`bucket_5678`?

We could ask the authorization server to generate a token with only that specific
access:

```
Biscuit {
    symbols: ["authority", "ambient", "resource", "operation", "right", "current_time", "revocation_id"]
    authority: Block[0] {
            symbols: []
            context: ""
            version: 1
            facts: [
                right(#authority, "bucket_5678", "/folder1/hello.txt", #read)
            ]
            rules: []
            checks: []
        }
    blocks: [
    ]
}
```

Without a `user_id`, the verifier would be unable to generate more `right` facts
and would only have the one provided by the token.

But we could also take the first token, and restrict it by adding a block containing
a new check:

```
Biscuit {
    symbols: ["authority", "ambient", "resource", "operation", "right", "current_time", "revocation_id", "user_id"]
    authority: Block[0] {
            symbols: ["user_id"]
            context: ""
            version: 1
            facts: [
                user_id(#authority, "user_1234"),
            ]
            rules: []
            checks: []
        }
    blocks: [
        Block[1] {
            symbols: ["caveat1", "read"]
            context: ""
            version: 1
            facts: []
            rules: []
            checks: [
                check if resource(#ambient, "bucket_5678", "/folder1/hello.txt"), operation(#ambient, #read)
            ]
        }

    ]
}
```

With that token, if the holder tried to do a `PUT /bucket_5678/folder1/hello.txt`
request, we would end up with the following facts:

```
user_id(#authority, "user_1234");
operation(#ambient, #write);
resource(#ambient, "bucket_5678", "/folder1/hello.txt");
current_time(#ambient, 2020-11-17T12:00:00+00:00);
owner(#authority, "user_1234", "bucket_1234");
owner(#authority, "user_1234", "bucket_5678");
owner(#authority, "user_ABCD", "bucket_ABCD");
right(#authority, "bucket_5678", "/folder1/hello.txt", #write);
```

The verifier's policy would still succeed, but the check from block 1 would
fail because it cannot find `operation(#ambient, #read)`.

By playing with the facts provided on the token and verifier sides, generating
data through rules, and restricting access with a series of checks, it is
possible to build powerful rights management systems, with fine grained controls,
in a small, cryptographically secured token.
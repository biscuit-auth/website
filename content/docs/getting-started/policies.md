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
- a check list: each check validates the presence of a fact. Example: `check if time($time), $time < 2022-01-01T00:00:00Z` for an expiration date. If one or more checks fail, the request is denied
- allow/deny policies: a list of policies that are tried in sequence until one of them matches. If it is an allow policy, the request is accepted, while if it is a deny policy (or none matched), the request is denied. Example: `allow if resource($res), operation($op), right($res, $op)`

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

Please see the [datalog reference page](../../datalog/reference/) for more info.

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
  resource($path),
  $path.matches("file[0-9]+.txt")
```

This check matches only if there exists a `resource($path)` fact for
which `$path` matches a pattern.

## Allow and deny policies

The validation in Biscuit relies on a list of allow or deny policies, that are
evaluated after all of the checks have succeeded. Like checks, they are queries
that must find a matching set of fact to succeed. If they do not match, we try
the next one. If they succeed, an allow policy will make the request validation
succeed, while a deny policy will make it fail. If no policy matched, the
validation will fail.

Example policies:

```
// verifies that we have rights for this request
allow if
  resource($res),
  operation($op),
  right($res, $op);

// otherwise, allow if we're admin
allow if is_admin();
```

## Blocks

A token is made of blocks of data cryptographically verified. A block can contain
facts, rules and checks. Their order affects execution: rules and checks can only
apply to facts created in their own block or previous blocks.

This is how security is guaranteed:

- the first block contains facts representing the basic rights. They are loaded into the
Datalog engine, along with the authorizer's facts, rules, checks and policies. They will
not execute on the following block data
- they are all executed and verified in that context
- for every following block, we load their facts and rules, execute their rules and apply
their checks. They can only see facts from previous blocks.

That way, a token cannot increase its rights when adding blocks; the only way they can
change execution is by adding checks covering previous blocks.

# Example tokens

Let's make an example, from an S3-like application, on which we can store and
retrieve files, with users having access to "buckets" holding a list of files.

Here is a first example token, that will hold a user id. This token only
contains one block, that has been signed with the root private key. The
verifier's side knows the root public key and, upon receiving the request,
will deserialize the token and verify its signature, thus authenticating
the token.

<bc-token-printer biscuit="EocBCh0KBHVzZXIKCXVzZXJfMTIzNBgCIggKBggHEgIYCBIkCAASIIPrUMvLX3ott2ZS3NDj_mEyaljWpg66t2vVGYrLeKE2GkDSsL9rpeAWGz3h9X6xXAw26xMgGh8oHL_x6e1uZCOGyXlq7NKxkPR9q1CU8_5GlR1Hk20qUYkHTlNX8NzmowYGIiIKIAQ6WdXjpxXh6xLqyA14fI6ZGbcsK9odaAoEx9Cs59r2"></bc-token-printer>


Here the token carries a single block, `authority`, that is the initial block containing basic rights, which can be refined in subsequent blocks.

A block can contain:

 - `facts`: each block can define new facts
 - `rules` each block can define new rules
 - `checks` each block can define new checks (queries that need to match in order to make the biscuit valid)

Let's assume the user is sending this token with a `PUT /bucket_5678/folder1/hello.txt` HTTP
request. The verifier would then load the token's facts and rules, along with
facts from the request:

```
user("user_1234");
operation("write");
resource("bucket_5678", "/folder1/hello.txt");
time(2020-11-17T12:00:00+00:00);
```

The verifier would also be able to load authorization data from its database,
like ownership information: `owner("user_1234", "bucket_1234")`,
`owner("user_1234", "bucket_5678")` `owner("user_ABCD", "bucket_ABCD")`.
In practice,this data could be filtered by limiting it to facts related to
the current ressource, or extracting the user id from the token with a query.

The verifier can also load its own rules, like creating one specifying rights
if we own a specific folder:

```
// the resource owner has all rights on the resource
right($bucket, $path, $operation) <-
  resource($bucket, $path),
  operation($operation),
  user($id),
  owner($id, $bucket)
```

This rule will generate a `right` fact if it finds data matching the variables.

We end up with a system with the following facts:

```
user("user_1234");
operation("write");
resource("bucket_5678", "/folder1/hello.txt");
current_time(2020-11-17T12:00:00+00:00);
owner("user_1234", "bucket_1234");
owner("user_1234", "bucket_5678");
owner("user_ABCD", "bucket_ABCD");
right("bucket_5678", "/folder1/hello.txt", "write");
```

At last, the verifier provides a policy to test that we have the rights for this
operation:

```
allow if
  right($bucket, $path, $operation),
  resource($bucket, $path),
  operation($operation);
```

Here we can find matching facts, so the request succeeds. If the request was
done on `bucket_ABCD`, we would not be able to generate the `right` fact for
it and the request would fail.

Now, what if we wanted to limit access to reading `/folder1/hello.txt` in
`bucket_5678`?

We could ask the authorization server to generate a token with only that specific
access:

<bc-token-printer biscuit="EqUBCjsKC2J1Y2tldF81Njc4ChIvZm9sZGVyMS9oZWxsby50eHQKBHJlYWQYAiIQCg4IBBICGAcSAhgIEgIYCRIkCAASIFmurdZP3Bxp7Y7KU4uMHfn8_DvPNNCtY1keOYHAtzDlGkCp_FQE6mssE5QKKZZKJXYU-fBMlZoqk7vFoNWEJsCjfbTTJ13adV-X3BIDmgix3MtjeU5jNRdzT7ukUYWX4moFIiIKIIrwKKUVBI2l0Ur3VhzUVDOJa5Z3jbirRUUEyUaVH8jK"></bc-token-printer>

Without a `user`, the verifier would be unable to generate more `right` facts
and would only have the one provided by the token.

But we could also take the first token, and restrict it by adding a block containing
a new check:

<bc-token-printer biscuit="EocBCh0KBHVzZXIKCXVzZXJfMTIzNBgCIggKBggHEgIYCBIkCAASIIPrUMvLX3ott2ZS3NDj_mEyaljWpg66t2vVGYrLeKE2GkDSsL9rpeAWGz3h9X6xXAw26xMgGh8oHL_x6e1uZCOGyXlq7NKxkPR9q1CU8_5GlR1Hk20qUYkHTlNX8NzmowYGGrYBCkwKBXF1ZXJ5CgtidWNrZXRfNTY3OAoSL2ZvbGRlcjEvaGVsbG8udHh0CgRyZWFkGAIyGgoYCgIICRIKCAISAhgKEgIYCxIGCAMSAhgMEiQIABIgD1TwTlGCPt97O9PwxHXm_f-Z1gBdhmNQzLm0FBLn9wUaQEtZ-OOxmVbp7ahlGbjOMOaUk5F_F1kwPiFUSF02sWMWDI5uwBsp2gpGiyRuPd3wneA2ZU0H3wDNjXAM1j-LdQoiIgogCCMQbcjX-YsOBZJeWLR8wNu9b7RpdxhQnk4d5ezXjuw="></bc-token-printer>

With that token, if the holder tried to do a `PUT /bucket_5678/folder1/hello.txt`
request, we would end up with the following facts:

```
user("user_1234");
operation("write");
resource("bucket_5678", "/folder1/hello.txt");
current_time(2020-11-17T12:00:00+00:00);
owner("user_1234", "bucket_1234");
owner("user_1234", "bucket_5678");
owner("user_ABCD", "bucket_ABCD");
right("bucket_5678", "/folder1/hello.txt", "write");
```

The verifier's policy would still succeed, but the check from block 1 would
fail because it cannot find `operation("read")`.

By playing with the facts provided on the token and verifier sides, generating
data through rules, and restricting access with a series of checks, it is
possible to build powerful rights management systems, with fine grained controls,
in a small, cryptographically secured token.

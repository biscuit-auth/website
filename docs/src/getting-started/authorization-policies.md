# Authorization policies 

## Datalog authorization policies

A Biscuit token could be verified by applications in various languages. To make sure that authorization policies are interpreted the same way everywhere, and to avoid brittle solutions based on custom parsers of text fields, Biscuit specifies an authorization language inspired from [Datalog](https://en.wikipedia.org/wiki/Datalog), that must be parsed and executed identically by every implementation.

Logic languages are well suited for authorization policies, because they can represent complex relations between elements (like roles, groups, hierarchies) concisely, and efficiently explore and combine multiple rules.

Biscuit's language loads facts, data that can comes from the token (user id), from the request (file name, read or write access, current date) or the application's internal databases (users, roles, rights).

Then it uses those facts to decide whether the request is allowed to go trough. It does so through two mechanisms:

- a check list: each check validates the presence of one or more facts. **Every check must succeed for the request to be allowed.**
  Example: `check if time($time), $time < 2022-01-01T00:00:00Z` for an expiration date.
- allow/deny policies: a list of policies that are tried in sequence until _one of them matches_. If it is an allow policy, the request is accepted, while if it is a deny policy the request is denied. If no policy matches, the request is also denied.
  Example: `allow if resource($res), operation($op), right($res, $op)`.

Allow/deny policies can only be defined in the application, while checks can come from the application or the token: tokens can only add _restrictions_ (through checks), while only the application can approve a token (by defining an `allow` policy).

Tokens can be attenuated by appending a block containing checks.

### First code example

Here we model an application allowing read or write access to files. It issues API tokens to logged-in users, and those tokens can be scoped to only allow specific operations. 

Let's consider a user whose user id is `"1234"`, and who has generated a token which is only allowed to perform a read operation on `.txt` files.

The user then issues the following HTTP request on the service API: `GET /files/file1.txt`.

Here is how the scenario can be expressed with datalog:

<bc-datalog-playground>
<pre><code class="block">
// the token contains information about its holder
user("1234");
// the token contains checks:
// it is only usable for read operations
check if operation("read");
// it is only usable on txt files.
check if resource($file), $file.ends_with(".txt");
</code></pre>
<pre><code class="authorizer">
// the application provides context about the request:
resource("file1.txt"); // based on the request path
operation("read"); // based on the request HTTP method
// the application only accepts tokens which contain user information
allow if user($u);
</code></pre>
</bc-datalog-playground> 

It is important to remember that fact names (`user`, `resource`, `operation`) don't have a specific meaning within datalog. As long as facts names are consistent between facts and checks / policies, they can be named freely (within syntaxic rules).

## Datalog in Biscuit

While this page gives an overview of how datalog works and can be used to describe access control, [complete datalog reference](../reference/datalog.md) is available for a detailed description of the datalog engine inner workings, as well as a list of all available functions and operations.

### Checks

The first part of the authorization logic comes with checks. They are queries over the Datalog facts. If the query produces something, if the underlying rule generates one or more facts, the check is validated. If the query does not produce anything, the check fails. For a token verification to be successful, all of the checks must succeed.

In the previous example, there are two checks:

<bc-datalog-editor>
<pre><code>
// the token contains checks:
// it is only usable for read operations
check if operation("read");
// it is only usable on txt files.
check if resource($file), $file.ends_with(".txt");
</code></pre>
</bc-datalog-editor> 

The first one ensures that the fact `operation("read")` is present. This kind of fact (information about the request) is often called an _ambient fact_. Common ambient facts are `resource(…)` (the resource being accessed), `operation(…)` (the operation being attempted), `time(…)` (the datetime at which the request has been received).

The second check is a bit more sophisticated: instead of matching an exact fact, it starts by matching _any_ fact named `resource()`, and binds a variable named `$file`
to the actual resource name. It then checks that the resource name ends with `".txt"`. Here, `$file.ends_with(".txt")` is an _expression_. For the check to be valid,
_all the expressions it contains must evaluate to `true`_.

Checks can contain several _predicates_ (something matching on facts and introducing variables) and several _expressions_:

- all the _predicates_ must match existing facts
- if a variable appears several times, all the values must match
- all the expressions must evaluate to `true`

Let's illustrate this with an example: a check that ensures that a user can perform an operation on a resource only if explicitly allowed by a corresponding fact `right()`.
The check also ensures that the operation is either `read` or `create`.

<bc-datalog-playground>
<pre><code class="authorizer">
user("1234");
operation("read");
resource("file1.txt");
right("1234", "file1.txt", "read");
check if user($u),
  operation($o), resource($r), right($u, $r, $o),
  ["read", "create"].contains($o);
allow if true;
</code></pre>
</bc-datalog-playground> 

### Allow and deny policies

The validation in Biscuit relies on a list of allow or deny policies that are evaluated after all of the checks have succeeded. Like checks, they are queries that must find a matching set of facts to succeed. If they do not match, we try the next one. If they succeed, an allow policy will make the request validation succeed, while a deny policy will make it fail. If no policy matched, the validation will fail.

Example policies:

<bc-datalog-editor>
<pre><code>
// verifies that we have rights for this request
allow if
  resource($res),
  operation($op),
  right($res, $op);
// otherwise, allow if we're admin
allow if is_admin();
</code></pre>
</bc-datalog-editor> 

### Blocks

A token is made of blocks of cryptographically verified data. 
Each token has at least one block called the authority block. Only the authority block is created and signed by the token emitter, while other blocks can be freely added by intermediate parties. By default, blocks added after the authority block are
self-contained and can only restrict what the token can do.

A block can contain:

- `facts`: They represent data. Each block can define new facts.
- `rules`: They can generate new facts from existing ones. Each block can define new rules.
- `checks`: They are queries that need to match in order to make the biscuit valid. Each block can define new checks.

*In most cases, the purpose of a block is to add checks that depend on facts provided by the authorizer.*

Here is how security is guaranteed:

- All the facts and rules from the token are loaded in the datalog engine; they are tied to the block that defined them.
- All the facts and rules from the authorizer are loaded in the datalog engine.
- Rules are repeatedly applied until no new fact is generated. By default, *rules are only applied on facts defined in the
  authority block, the authorizer or the block that defined the rule.* This way, *facts defined in a non-authority block can only be seen from the block itself.*
- Checks are applied on the facts. By default, *checks are only applied on facts defined in the authority block, the authorizer or the block that defined the check.* This way, *facts defined in a non-authority block can only fulfil checks from the same block*.
- Authorizer policies are applied on the facts. By default, *policies are only applied on facts defined in the authority block or the
authorizer.* This way, *facts defined in a non-authority block cannot fulfil authorizer policies.*

![datalog block scoping](/images/block-scoping.svg)

This model guarantees that adding a block can only restrict what a token can do: by default, the only effect of adding a block to a token is to add new checks.

<bc-datalog-playground showBlocks="true">
<pre><code class="block">
// the token emitter grants read access to file1
right("file1", "read");
// the authority block trusts facts from itself and the authorizer
check if action("read");
</code></pre>
<pre><code class="block">
right("file2", "read");
// blocks trust facts from the authority block and the authorizer
check if action("read");
// blocks trust their own facts
check if right("file2", "read");
</code></pre>
<pre><code class="authorizer">
resource("file1");
action("read");
// the authorizer does not trust facts from additional blocks
check if right("file2", "read");
// the authorizer trusts facts from the authority block
check if right("file1", "read");
allow if true;
</code></pre>
</bc-datalog-playground> 

It is possible for a rule, a check or a policy to consider facts defined in non-authority third-party blocks by explicitly providing the external public part of the keypair that signed the block. This allows considering facts from a non-authority block while still making sure they come from a trusted party.

## Example tokens

Let's make an example from an S3-like application on which we can store and retrieve files, with users having access to "buckets" holding a list of files.

Here is a first example token, that will hold a user id. This token only contains one block, that has been signed with the root private key. The authorizer's side knows the root public key and, upon receiving the request, will deserialize the token and verify its signature, thus authenticating the token.

<bc-token-printer biscuit="En0KEwoEMTIzNBgDIgkKBwgKEgMYgAgSJAgAEiBw-OHV3egI0IVjiC1vdB7WZ__t0FCvB2s-81PexdwuqxpAolMr9XDP7T44qgdXxtumc2P3O93pCHaGSuBUs3_f8nsQJ7NU6PdkujZIMStzEJ36CDnxawSZjUAKoTO-a1cCDSIiCiBPsG53WHcpxeydjSpFYNYnvPAeM1tVBvOEG9SQgMrzbw=="></bc-token-printer>


Here the token carries a single block, `authority`, that is the initial block containing basic rights, which can be refined in subsequent blocks.

Let's assume the user is sending this token with a `PUT /bucket_5678/folder1/hello.txt` HTTP request. The authorizer would then load the token's facts and rules, along with facts from the request:

<bc-datalog-editor>
<pre><code>
user("1234");
operation("write");
resource("bucket_5678", "/folder1/hello.txt");
time(2020-11-17T12:00:00+00:00);
</code></pre>
</bc-datalog-editor> 

The authorizer would also be able to load authorization data from its database, like ownership information: `owner("1234", "bucket_1234")`, `owner("1234", "bucket_5678")` `owner("ABCD", "bucket_ABCD")`. In practice, this data could be filtered by limiting it to facts related to the current ressource, or extracting the user id from the token with a query.

The authorizer can also load its own rules, like creating one specifying rights if we own a specific folder:

<bc-datalog-editor>
<pre><code>
// the resource owner has all rights on the resource
right($bucket, $path, $operation) <-
  resource($bucket, $path),
  operation($operation),
  user($id),
  owner($id, $bucket)
</code></pre>
</bc-datalog-editor> 

This rule will generate a `right` fact if it finds data matching the variables.

We end up with a system with the following facts:

<bc-datalog-editor>
<pre><code>
user("1234");
operation("write");
resource("bucket_5678", "/folder1/hello.txt");
time(2020-11-17T12:00:00+00:00);
owner("1234", "bucket_1234");
owner("1234", "bucket_5678");
owner("ABCD", "bucket_ABCD");
right("bucket_5678", "/folder1/hello.txt", "write");
</code></pre>
</bc-datalog-editor> 

At last, the authorizer provides a policy to test that we have the rights for this operation:

<bc-datalog-editor>
<pre><code>
allow if
  right($bucket, $path, $operation),
  resource($bucket, $path),
  operation($operation);
</code></pre>
</bc-datalog-editor> 

Here we can find matching facts, so the request succeeds. If the request was done on `bucket_ABCD`, we would not be able to generate the `right` fact for it and the request would fail.

Now, what if we wanted to limit access to reading `/folder1/hello.txt` in `bucket_5678`?

We could ask the authorization server to generate a token with only that specific access:

<bc-token-printer biscuit="EqEBCjcKC2J1Y2tldF81Njc4ChIvZm9sZGVyMS9oZWxsby50eHQYAyISChAIBBIDGIAIEgMYgQgSAhgAEiQIABIgCxu0Xjo6dUhbxvvSZWXktNjkYwNVCJdX4Oc0VjbzFMYaQDdAHC244NGJcyhz75EqL56BnrOrquIOS5kW-hMoTVmFP846WGSQEeMhnyWhB6_ibg8HCtlrZ2beihSul3lEnwQiIgogFHWo9rDbhDCZbh3gsUjbn-8rCGhpmukxsphfZKJKoZM="></bc-token-printer>

Without a `user`, the authorizer would be unable to generate more `right` facts and would only have the one provided by the token.

But we could also take the first token, and restrict it by adding a block containing a new check:

<bc-token-printer biscuit="En0KEwoEMTIzNBgDIgkKBwgKEgMYgAgSJAgAEiBw-OHV3egI0IVjiC1vdB7WZ__t0FCvB2s-81PexdwuqxpAolMr9XDP7T44qgdXxtumc2P3O93pCHaGSuBUs3_f8nsQJ7NU6PdkujZIMStzEJ36CDnxawSZjUAKoTO-a1cCDRqrAQpBCgtidWNrZXRfNTY3OAoSL2ZvbGRlcjEvaGVsbG8udHh0GAMyHAoaCgIIGxIMCAISAxiBCBIDGIIIEgYIAxICGAASJAgAEiBl-6CdFUkuctDhcpZv7_xra-IVXuuaC5hBKgOZbPdVoRpAslJIfbaa076hHmML-VhU7t-73iaiHWZu95G7AFFiPEuPIygBlmcxP5MZh_H4wN-TDLdy8JwcRazvajhhwMVNBCIiCiDERGgv9mgdpHxUp16L83cjMLzYQAu9_C5KESRC1dmNSA=="></bc-token-printer>

With that token, if the holder tried to do a `PUT /bucket_5678/folder1/hello.txt` request, we would end up with the following facts:

<bc-datalog-editor>
<pre><code>
user("1234");
operation("write");
resource("bucket_5678", "/folder1/hello.txt");
time(2020-11-17T12:00:00+00:00);
owner("1234", "bucket_1234");
owner("1234", "bucket_5678");
owner("ABCD", "bucket_ABCD");
right("bucket_5678", "/folder1/hello.txt", "write");
</code></pre>
</bc-datalog-editor> 

The authorizer's policy would still succeed, but the check from block 1 would fail because it cannot find `operation("read")`.

By playing with the facts provided on the token and authorizer sides, generating data through rules, and restricting access with a series of checks, it is possible to build powerful rights management systems, with fine grained controls, in a small, cryptographically secured token.

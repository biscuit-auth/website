# Common patterns

As a specification, biscuit does not mandate specific ways to use datalog. As far as authorization logic is concerned,
there are no built-in facts with specific  behaviour. That being said, some patterns are common and while not part of
the spec, are codified in libraries and tools. Finally, using specific fact names can help with reducing token size.

## Expiration check

The CLI and the rust library (among others) use the `time()` fact to represent the instant in time where the token is used.
This provides a way to encode expiration dates in tokens:

<bc-datalog-editor readonly="readonly">
   <code>
check if time($time), $time <= 2022-03-30T20:00:00Z;
  </code>
</bc-datalog-editor>

It only depends the authorizer and tokens use the same fact name (here, `time()`). It would work with other fact names,
but the existing tooling provides helpers using `time()`, so it is better to be consistent with it. Additionally, `time()`
is part of the [default symbol table](#default-symbols), so using it will result in smaller tokens.

<details>
<summary>Interactive example</summary>
<bc-datalog-playground showBlocks="true">
  <code class="block">
check if time($time), $time <= 2022-03-30T20:00:00Z;
  </code>
  <code class="authorizer">
// the authorizer can provide a fact containing the current time
time(2022-03-30T19:00:00Z);
allow if true;
  </code>
</bc-datalog-playground>
</details>

Attenuation can add more expiration checks, and all of them will be tested.

<details>
<summary>Interactive example</summary>
<bc-datalog-playground showBlocks="true">
  <code class="block">
check if time($time), $time <= 2022-03-30T20:00:00Z;
  </code>
    <code class="block">
check if time($time), $time <= 2022-03-30T18:30:00Z;
  </code>
  <code class="authorizer">
// the authorizer can provide a fact containing the current time
time(2022-03-30T19:00:00Z);
allow if true;
  </code>
</bc-datalog-playground>
</details>

## Capabilities

The `right()` fact is commonly used to describe access rights. Depending on the context, it can be used with several values:

<bc-datalog-editor>
  <code>
right("read"); // read-only access to everything for the token holder
right("resource1", "read") // read-only access to resource1 for the token holder
right("user1", "resource1", "read") // read-only access to resource1 for user1
  </code>
</bc-datalog-editor>

Usually, a `right()` fact carried in a token will not mention a user id and will refer to the token holder. `right()` facts
defined server-side (such as in an access rights matrix) will mention an identifier. Tokens carrying a user identifier
usually do so with the `user()` fact.

## Per request attenuation

In an API with authorization, the client would typically hold a long lived
token with large rights. But when executing a single request, we can attenuate
the token so that it is only usable for that specific request.
Then if the request's token gets stolen, it will limit its impact.

Let's use a basic token containing a user id, that would have access to everything
owned by that user, and do a GET HTTP request on "/articles/1":

<bc-datalog-playground showBlocks="true">
  <code class="block">
user(1234);
  </code>
  <code class="authorizer">
// the authorizer provides the current date, the resource being accessed and the operation being performed
time(2022-03-30T19:00:00Z);
operation("read");
resource("/articles/1");
// the authorizer provides a series of rights for the given user
right(1234, "/articles/1", "read");
right(1234, "/articles/1", "write");
right(1234, "/articles/2", "read");
right(1234, "/articles/2", "write");
// the request is allowed if the user has sufficient rights for the current operation
allow if user($user), right($user, "/articles/1", "write");
  </code>
</bc-datalog-playground>

Instead we can make a token that would only be valid for that request, with a short
expiration date:

<bc-datalog-playground showBlocks="true">
  <code class="block">
user(1234);
  </code>
    <code class="block">
check if time($date), $date <= 2022-03-30T19:00:10Z;
check if operation("read");
check if resource("/articles/1");
  </code>
  <code class="authorizer">
// the authorizer provides the current date, the resource being accessed and the operation being performed
time(2022-03-30T19:00:00Z);
operation("read");
resource("/articles/1");
// the authorizer provides a series of rights for the given user
right(1234, "/articles/1", "read");
right(1234, "/articles/1", "write");
right(1234, "/articles/2", "read");
right(1234, "/articles/2", "write");
// the request is allowed if the user has sufficient rights for the current operation
allow if user($user), right($user, "/articles/1", "write");
  </code>
</bc-datalog-playground>

So if we tried to use it on another endpoint, it would fail:

<bc-datalog-playground showBlocks="true">
  <code class="block">
user(1234);
  </code>
    <code class="block">
check if time($date), $date <= 2022-03-30T19:00:10Z;
check if operation("read");
check if resource("/articles/1");
  </code>
  <code class="authorizer">
// the authorizer provides the current date, the resource being accessed and the operation being performed
time(2022-03-30T19:00:00Z);
operation("write");
resource("/articles/1/comments");
// the authorizer provides a series of rights for the given user
right(1234, "/articles/1", "read");
right(1234, "/articles/1", "write");
right(1234, "/articles/2", "read");
right(1234, "/articles/2", "write");
// the request is allowed if the user has sufficient rights for the current operation
allow if user($user), right($user, "/articles/1/comments", "write");
  </code>
</bc-datalog-playground>

This method relies on the authorizer providing the facts to match on the request. It can be extended further by providing
more data, like a list of HTTP headers or a cryptographic hash of the body.

## Default symbols

In order to reduce the size of tokens, the biscuit specification defines a list of strings that can be used in tokens
without having to be serialized. Common symbols are thus almost free to use and won't increase the size of the token.
It is thus then good practice to use those strings as fact names or terms, _as long as they make sense_.

- read
- write
- resource
- operation
- right
- time
- role
- owner
- tenant
- namespace
- user
- team
- service
- admin
- email
- group
- member
- ip_address
- client
- client_ip
- domain
- path
- version
- cluster
- node
- hostname
- nonce
- query

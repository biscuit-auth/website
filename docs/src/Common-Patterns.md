# Common patterns

## Expiration check

If the authorizer provides the current time when executing policies,
the token can then carry an expiration date:

<bc-datalog-playground showBlocks="true">
  <code class="block">
check if time($date), $date <= 2022-03-30T20:00:00Z;
  </code>
  <code class="authorizer">
// the authorizer can provide a fact containing the current date
time(2022-03-30T19:00:00Z);
allow if true;
  </code>
</bc-datalog-playground>

Attenuation can add more expiration checks, and all of them will be tested:

<bc-datalog-playground showBlocks="true">
  <code class="block">
check if time($date), $date <= 2022-03-30T20:00:00Z;
  </code>
    <code class="block">
check if time($date), $date <= 2022-03-30T18:30:00Z;
  </code>
  <code class="authorizer">
// the authorizer can provide a fact containing the current date
time(2022-03-30T19:00:00Z);
allow if true;
  </code>
</bc-datalog-playground>

## Per request attenuation

In an API with authorization, the client would typically hold a long lived
token with large rights. But when executing a single request, we can attenuate
the token so that it is only usable for that specific request.
Then if the request's token gets stolen, it will limit its impact.

Let's use a basic token containing a user id, that would have access to everything
owned by that user, and do a PUT HTTP request on "/articles/1":

<bc-datalog-playground showBlocks="true">
  <code class="block">
user(1234);
  </code>
  <code class="authorizer">
// the authorizer provides the current date, the API endpoint and HTTP method
time(2022-03-30T19:00:00Z);
method("PUT");
endpoint("/articles/1");
allow if true;
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
check if method("PUT");
check if endpoint("/articles/1");
  </code>
  <code class="authorizer">
// the authorizer provides the current date, the API endpoint and HTTP method
time(2022-03-30T19:00:00Z);
method("PUT");
endpoint("/articles/1");
allow if true;
  </code>
</bc-datalog-playground>

So if we tried to use it on another endpoint, it would fail:

<bc-datalog-playground showBlocks="true">
  <code class="block">
user(1234);
  </code>
    <code class="block">
check if time($date), $date <= 2022-03-30T19:00:10Z;
check if method("PUT");
check if endpoint("/articles/1");
  </code>
  <code class="authorizer">
// the authorizer provides the current date, the API endpoint and HTTP method
time(2022-03-30T19:00:00Z);
method("POST");
endpoint("/articles/1/comment");
allow if true;
  </code>
</bc-datalog-playground>

This method relies on the authorizer providing the facts to match on the request.
It can be extended further by providing more data, like a list of HTTP headers
or a cryptographic hash of the body.

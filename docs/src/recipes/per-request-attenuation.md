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
resource("/articles/1");
operation("read");
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
resource("/articles/1");
operation("read");
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
resource("/articles/1/comments");
operation("write");
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

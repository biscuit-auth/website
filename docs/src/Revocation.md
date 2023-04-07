# Revocation

## Revocation identifiers

Once a token has been created, we need a way to invalidate it, either due to its lifecycle,
like logging out or decommissioning a service, or because it was compromised. Tokens can come with
an expiration date, but they are not sufficient, as there will always be some delay between the leak
and the expiration date. So we need a way to revoke currently existing tokens.

Revoking bearer tokens like biscuits is usually done through revocation lists: a list of
tokens that are no longer accepted is shared with all verifying parties. When authorizing a biscuit token,
the library will look it up in the list and refuse the request if it finds it.

Such a mechanism relies on being able to uniquely identify tokens: we want to revoke only the tokens
that are not valid anymore, without affecting other tokens (even tokens with the same content that have been issued
to another holder). With offline attenuation, biscuits introduce another constraint: revoking a token should also
revoke all derived tokens (else it would be trivial to circument revocation).

The biscuit spec (and libraries) provides you with:

 - a way to uniquely identify tokens (two biscuits with the same payload and secret key will be different)
 - a way to identify groups of tokens derived from the same parent token
 - a way to reject tokens based on that identification during authorization

Biscuit's revocation identifiers are unique and generated directly from the token's structure, there is no need to add
them explicitely, as would be done with Macaroons or the  `jti` claim in JWT.

The biscuit spec _does not mandate_ how to publish revocation ids within your system;
that depends a lot on the architecture and constraints.
You can start simple with static revocation lists read through environment variables, and migrate to more complex systems as needed.
We describe in this document various ways to achieve it.

### Listing revocation ids for a token

The [CLI](./Command-Line.md#verify-a-token) can be used to inspect revocation ids:

```
❯ biscuit inspect test9_expired_token.bc --raw-input
Authority block:
== Datalog ==

== Revocation id ==
16d0a9d7f3d29ee2112d67451c8e4ff07bd5366a6cdb082cf4fcb66e6d15a57a22009ef1018fc4d0f9184edb0900df161807bc6f8287275f32eae6b5b1c57100

==========

Block n°1:
== Datalog ==
check if resource("file1");
check if time($date), $date <= 2018-12-20T00:00:00+00:00;

== Revocation id ==
0670d948462e0cc248ce45b7ea04cbfb126a7559c8d60b533f7f0a92696900ee4e432780b526462b845d372c9b7b223c43efc22e0441b14b0bc4661e05ebfe03

==========

🙈 Public key check skipped 🔑
🙈 Datalog check skipped 🛡️
```

### Providing a revocation list during biscuit authorization

* [In haskell](./Haskell.md#reject-revoked-tokens)
* [In rust](./Rust.md#reject-revoked-tokens)

## Why should we plan for token revocation?

There are two competing approaches to session management in authorization, that will drive
architectural decisions:
- in *stateful* systems, all authorizations are performed through one service or database
that holds the list of currently active sessions
- in *stateless* systems, authorization can be performed independently in any service, only
using information from the token and the service. In particular, the service cannot know
about all of the currently active sessions (there may not even be a concept of session)

Those two solutions are often compared on their ability to close a session. Why? Can't we
just set an expiration date? Unfortunately, even an with expiration date we would still need a way to close
a session, to implement the log out functionality. That feature is common, expected by users,
and needed in multiple situations (ex: public computer, disconnecting sessions from a stolen
phone). Even for purely service to service communication, we will need to close the access
once the client service is decommissioned.

In stateful systems, closing a session is easy: we delete the session's information from the
database and that's it. In stateless systems, this is more complex: how do we make sure
all services know that the session is invalid? That means reintroducing some shared state,
so is the stateless design impossible after all? Shouldn't we go back to stateful systems?

If the architecture we are designing can rely on a central state, it will be the simplest
approach and probably the right solution. But there are good reasons to choose the stateless
design:
- **scaling**: a central authorization service that is queried on every request is a single point
of failure for the entire system. If it is down, nobody can log in, but existing sessions will
fail too. A stateless approach will decouple session creation from authorization, so existing
sessions can still work when the authentication service fails.
- **isolation**: the service receiving the request might be less trusted and should not be
able to access session information.
- **authentication delegation**: authentication could be in a separate service (example: SSO)
that can't be queried on every request. That service could even be managed by a different
company.

In those cases, separating authorization from session creation makes sense, but then how do
we close a session? It is usually done through token revocation: the authorizer needs to
know a list of tokens that must be refused, and that list changes dynamically, so we are
reintroducing some state in the system.

But revocation has properties that make it nice to implement in stateless architectures:
- we do not need to know about all of the tokens, only those that were revoked, so the list
will be much smaller
- the list of revoked tokens will naturally grow, but if tokens have an expiration date, they
can be purged from the list after a while
- it is read-oriented and highly cacheable: once a token was added to the revocation list,
we won't modify its entry (except when purging), so we don't need synchronization or consensus
- revocation lists do not hold any critical or private information, they can be shared with
every service

So handling revocation is adding some shared state, but much more limited than what we would
have with a fully centralized architecture.

## How to implement revocation in our infrastructure?

We need a reliable way to transmit revocation information to services. That will depend on
how quickly we want to disseminate it, and how much complexity we can bear.

### The basic solution: read the revocation list at startup

In some cases, like communication between automated services, revocation is rare, mostly when
a service is stopped or a token is leaked, so the revocation list is mostly static and small. If we can accept some
manual operations, and a (slight) delay in synchronization, we can have services read the revocation list at startup. They
will check tokens from an in memory list, that will stay the same for the entire life of the
service (until it is restarted).

The tradeoff here is that if we need to revoke a token urgently, we will need to redeploy
a lot of services at once.

In the case where there is only one service accepting tokens, the revocation list can be read from config (a config file or environment variables).

In the case where more services accept tokens, it will become necessary to have a centrally
defined list that is then distributed to all services.
Since the revocation list is small and changes rarely, it can be stored as a file in an object
store like S3, and downloaded via HTTP. That file can be updated independently whenever
a service stops, or when one of the token expires or is leaked.

Depending on how quick you want revocation to take effect, you can either wait for the services to restart or trigger a restart of all affected services.

### Slightly more advanced: download the revocation list regularly

The natural next step from the previous solution: instead of downloading the list once, it
is downloaded regularly to keep it up to date. There is still a gap between revocation and
its deployment, but that gap is configurable, we can decide how often a service checks
the new list.

The list can still be stored in an object store. It is a good idea to rely on HTTP caching
solutions like the `ETag` or `If-Modified-Since` headers. If the revocation list grows
and/or becomes more dynamic, this solution will incur a lot of traffic.

### Download diffs

When the revocation list grows, it might be easier to only download the list of recently
revoked tokens. Since that list is append-only, the easiest way might be to store the
list in a database table with an incremented id column and give the latest id with the
revocation list. When services try to download the revocation list, they can send
their last known id, and the server can send the most recent changes.

While this relies on a central revocation service, it can be lighter than a stateful system
because that central service is queried out of band, on regular intervals, instead of
queried on each request of each service. Services will also be able to serve requests
when the revocation service is down.

This can still be implemented over HTTP and rely on caching. It still suffers from a small
delay before revocation is actually deployed.

### Queue based systems

When we want a more dynamic solution, where revocation spreads as soon as possible, we should
instead rely on a queue based system like RabbitMQ or Kafka, or even simpler with Server Sent
Events or WebSockets. In this architecture, every service subscribes on a queue on startup, and
receive newly revoked tokens as they are published.

This is the safest solution, as tokens are revoked everywhere as quickly as possible. It is also
more complex to deploy because it needs a queueing system that must be monitored, scaled, etc. And
every service must then integrate the client to connect to that queue.

Its usage will depend on the kind of queue provided by your system. With durable queues, a
new service would read all of the messages from the beginning, then receive a new message for a new
revoked token. If the service disconnects or restarts, it could reuse a saved local state and an
offset in this queue to avoid reading everything again. This requires regular maintenance on
the queue to remove expired tokens. With ephemeral queues, the service would need to get the initial
state out of band then receive the stream of updates.

## How the revocation service receives and stores data

The revocation service establishes the list of revoked tokens and regularly purges expired ones.
While this looks simple, there are details to consider.

First, the service that creates tokens (user authentication, or microservice manager) should
store the first block's revocation id, along with some metadata, like the creation date,
expiration date and expected usage (user id, service id, etc). If a token expires, it is removed
from the list. If a user logs out or a service is shut down, the revocation id and expiration
date are sent to the revocation service.

If we want to revoke an attenuated token, there are more steps. The user cannot just provide
the revocation ids, because we would have no way of knowing if they are trying to revoke
a parent token. In that case, the entire token should be presented, then we look up the root
block's expiration date in the data we already have, we extract the list of revocation ids
from the token, and send the latest one with the expiration date to the revocation service.

All tokens should come with an expiration date, to prevent the revocation list from growing
indefinitely.

### OAuth specific usage

In OAuth based systems, API clients hold an access token, used to query the API, and a refresh
token, used to get a new access token. The idea here is that the access token is used often
and potentially on less trusted services, so it has a short expiration, while the refresh
token has a longer lifetime because it is only used once in a while, and only with the
authorization server.

While it is common to see applications with a permanent refresh token, this will causes
issues with the revocation list, causing it to grow, and current practices evolved
towards a different approach.

It is now recommended to have a refresh token with an expiration date, that can be long,
and have that refresh token be single use. When it is sent to the authorization server
to get a new access token, the authorization server will revoke the old refresh token
and issue new refresh and access tokens. The interesting property here is that if the
authorization server sees the same refresh token twice, it means that the token was
stolen: either the thief or the legitimate client already used the refresh token, and
the other one is now requesting an access token too. In that case, the authorization
server must revoke all current refresh and access tokens for this client.

This solution also has the nice side effect that refresh token expiration can be much
shorter, since it is changed any time we change an access token.
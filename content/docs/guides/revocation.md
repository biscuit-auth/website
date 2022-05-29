+++
title = "Revocation"
description = "How to revoke a token"
date = 2021-05-01T08:00:00+00:00
updated = 2021-05-01T08:00:00+00:00
draft = false
weight = 10
sort_by = "weight"
template = "docs/page.html"

[extra]
lead = "How to revoke a token"
toc = false
top = false
+++

## Why should we plan for token revocation?

There are two competing approaches to session management in authorization, that will drive
architectural decisions:
- in *stateful* systems, all authorizations are performed through one service or database
that holds the list of currently active sessions
- in *stateless* systems, authorization can be performed independently in any service, only
using information from the token and the service. In particular, the service cannot know
about all of the currently active sessions

Those two solutions are often compared on their ability to close a session. Why? Can't we
just set an expiration date? Even with expiration date we would still need a way to close
a session, to implement the log out functionality. That feature is common, expected by users,
and needed in multiple situations (public computer, disconnecting sessions from a stolen
phone...)? Even for purely service to service communication, we will need to close the access
once the client service is decommissioned.

In stateful systems, closing a session is easy: delete the session's information from the
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
- we do not need to know about all of the tokens, only those that were revoked, which will
be much smaller
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
a service is stopped, or a token is leaked, so the revocation list is mostly static and small. If we can accept some
manual operations, and a (slight) delay in synchronization, we can have services read the revocation list at startup. They
will check tokens from an in memory list, that will stay the same for the entire life of the
service (until it is restarted).

The tradeoff here is that if we need to revoke a token urgently, we will need to redeploy
a lot of services at once.

In the case where there is only one service accepting tokens, the revocation list can be read from config (a config file or environment variables).

In the case where more services accept tokens, it will become necessary to have a centrally defined list that is then distributed to all services.
Since the revocation list is small and static, it can be stored as a file in an object
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
queried on each request of each service.

This can still be implemented over HTTP and rely on caching. It still suffers from a small
delay before revocation is actually deployed.

### Queue based systems

When we want a more dynamic solution, where revocation spreads as soon as possible, we should
instead rely on a queue based system, like RabbitMQ or Kafka, or even simpler with Server Sent
Events or WebSockets. In this architecture, every service subscribes on a queue on startup, and
receive newly revoked tokens as they are published.

This is the safest solution, as tokens are revoked everywhere as quickly as possible. It is also
more complex to deploy because it needs a queueing system that must be monitored, scaled, etc.

How to use it will depend on the kind of queue provided by your system. With durable queues, a
new service would read all of the messages from the beginning, then receive a new message for a new
revoked token. If the service disconnects or restarts, it could reuse a saved local state and an
offset in this queue to avoid reading everything again. This requires regular maintenance on
the queue to remove expired tokens. With ephemeral queues, the service would need to get the initial
state out of band then receive the stream of updates.

TODO:
- we need all services to know about the revocation information quickly enough (once a token
is revoked, it should soon be refused on every service)
- start simple: get the revocation list at startup, then see how to update it
- push VS pull?
  - push: the authentication system sends the list of recently revoked tokens to every service,
  possibly through a pub/sub or queue system. Drawback of this approach: we need a good inventory
  of the system and a robust way of sending information to deployed services. Otherwise, one
  of them might not receive updates. Advantage: as soon as a token is revoked, the revocation
  information is pushed to services, so we're not wasting time
  - pull: services regularly download the revocation list. Advantage: every service is responsible
  for downloading the list, no need for a good inventory. Drawbacks: there can be a slight delay
  in receiving updates. We might also receive alarge list (can we ask for the more recent list instead?)

expiration tips: short expiration with regular token exchange
do not limit tokens per IP but per world region and per user agent: IP can change a lot in
a session(mobile, etc) but sessions rarely jump quickly over the world or change user agent
- revocation ids in biscuit:
  - might need a list of currently active tokens, or at least their root revocation id, so it can
  be added to the revocation list when removing the session
  - how to handle revocation of an attenuated token? We cannot just accept a list of revocation ids,
  otherwise someone could revoke their attenuated token and all of the ancestor tokens. Send the
  token to the authentication service, and let it find the last block's revocation id?

## How the revocation service receives and stores data


## Revocation identifiers

Biscuit tokens are bearer tokens. Revoking bearer tokens is usually done through revocation lists: a list of
tokens that are no longer accepted is shared with all verifying parties. When authorizing a biscuit token,
the library will make sure the token has not been revoked.

Such a mechanism relies on being able to uniquely identify tokens: we want to be able to revoke only the tokens
that are not valid anymore, without revoking other tokens (even tokens with the same payload but have been issued
to another holder). With offline attenuation, biscuits introduce another constraint: revoking a token should also
revoke all derived tokens (else it would be trivial to circument revocation).

The biscuit spec (and libraries) provide you with:

 - a way to uniquely identify tokens (two biscuits with the same payload and secret key will be different)
 - a way to identify groups of tokens derived from the same parent token
 - a way to reject tokens based on their ids during authorization

The biscuit spec _does not mandate_ how to publish revoked ids within your system;
that depends a lot on the architecture and constraints of the systems.
You can start simple with static revocation lists read through environment variables, and migrate to more complex systems as needed.

### Listing revocation ids for a token

The [CLI](../../Usage/cli/#verify-a-token) can be used to inspect revocation ids:

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

#### In haskell

[Rejecting revoked ids in haskell](../../Usage/haskell/#reject-revoked-tokens)

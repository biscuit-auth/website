+++
title = "Delegation in microservices"
description = "Attenuating a token going through microservices"
date = 2021-05-01T08:00:00+00:00
updated = 2021-05-01T08:00:00+00:00
draft = false
weight = 10
sort_by = "weight"
template = "docs/page.html"

[extra]
lead = "Attenuating a token going through microservices"
toc = true
top = false
+++

In a microservices architecture, a request often does not happen in isolation.
It can trigger other requests to other services, and those can then contact
another set of services.

Authorizing those requests is challenging, because these services have varying
levels of trust. The API gateway would typically be highly trusted, while a service
at the end of a chain should only be trusted to perform its own task. If one of those
services were compromised, we want to limit its access to other services and data.

Usually, authorization in microservices is done in three different ways. The most
common one is point to point trust between services, often through mTLS. In that
approach, it is not the request itself that is authorized, but the origin. So a
compromised service would be able to do any requests to the services that trust it,
even modify or replay in flight requests. This flaw shows that we need to tie
authorization to the request, and link it to the entire request chain.

The second solution would use a random identifier carried from request to request,
and a central authorization service that we can ask to authorize a request. This is
a safe way to do it, because the authorizer can track the entire tree of requests,
which action they are trying to perform and on which microservice. It can decide
precisely if the request should be accepted.
Unfortunately, it introduces a large point of failure and scaling issues, as all
services need to query it before acting on a request. The impact can be reduced
with sidecar authorization services, but they introduce more complexity in the
infrastructure.

The third solution tries to sidestep that point of failure by carrying a JWT from
request to request, that carries the set of rights needed to perform them. Those
tokens can be verified decentrally, so that reduces scaling issues. But this
reintroduces securitiy holes: now any service can use the token it just received
to talk to more trusted services, and they will accept it.

Those partial solutions to microservice authorization show which features we
actually need:
- authorization must be tied to the request, not only the service sending the request
- authorization should be decentralized
- a service should not be able to query more trusted services

As it turns out, Biscuit tokens are well suited for this problem:
- any service that knows the root public key can verify a token
- tokens can be attenuated when going from one service to the next

Example?

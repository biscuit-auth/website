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
levels of trust. The API gateway, where user request are initially received,
 would typically be highly trusted, while a service
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
request to request, that holds the set of rights needed to perform them. Those
tokens can be verified decentrally, so that reduces scaling issues. But this
reintroduces security holes: now any service can use the token it just received
to talk to more trusted services, and they will accept it.

<img src="/img/microservices-jwt.svg" style="width: 100%" />

Those partial solutions to microservice authorization show which features we
actually need:

- authorization must be tied to the request, not only the microservice sending the request
- authorization should be decentralized
- a service should not be able to query more trusted services

We can meet those demands using Biscuit tokens. in this model, we would use tokens
holding the list of rights that a series of requests could perform, like "update cart",
"pay" or "send email". Any service that knows the root public key
and the authorization policies can verify the token and check that it matches the
request. At this point it works in the same way as JWT.

But now a microservice can take the token it received, generate an attenuated token
from it, and send the attenuated token with its own requests to other services.

As an example, let's imagine a ecommerce deployment, where we have 3 services, to
manage the cart, perform payment and send emails.
When we send a request to the cart management service to pay for the current cart,
we would add a token containing the check
`check if operation($op), ["update cart", "pay", "send email"].contains($op)`.
The cart service verifies the request, adding the `operation("update cart")` fact
to the authorizer. It sees that payment must be done, and a confirmation email
sent to the customer.
So it attenuates the token, adding the check
`check if operation($op), ["pay", "send email"].contains($op)`, and sends
that token along with a request to pay to the payment service.

<img src="/img/microservices-biscuit1.svg" style="width: 100%" />

The payment service can then verify that the request is authorized for a payment
operation, but it cannot use that token to query the cart service. Once the payment
is done, the payment service can attenuate further the token, adding the check
`check if operation("send email")` and send it with a request to the email service
to send a confirmation email to the customer. The email service cannot use that token
to modify the cart or request a payment, it is limited only to the task it can perform.

By relying on attenuation, we can make sure that each service only has the rights for
the tasks under its responsibility or that of services further in the chain, tying
authorization to each request and limiting the blast radius of a service compromise.
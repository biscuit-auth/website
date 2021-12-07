+++
title = "Introduction"
description = "Biscuit is an authorization token that can be verified with public key cryptography, attenuated offline, using a Datalog based language for authorization policies"
date = 2021-05-01T08:00:00+00:00
updated = 2021-05-01T08:00:00+00:00
draft = false
weight = 10
sort_by = "weight"
template = "docs/page.html"

[extra]
#lead = "Biscuit is an authorization token that can be verified with public key cryptography, attenuated offline, using a Datalog based language for authorization policies."
toc = true
top = false
+++

Biscuit is a set of building blocks for your authorization layer. By making a coherent experience from the authorization token up to the tools to write policies, it spares you the time spent binding together token scopes, authorization servers, and making sure authorization policies execute correctly in every service. You only need to focus on writing, debugging and deploying your rules.

## Biscuit is a bearer token

One of those building blocks is an authorization token that is signed with public key cryptography (like JWT), so that any service knowing the public key can verify the token. But it does a lot more! It supports offline attenuation (like Macaroons): from a Biscuit token, you can create a new one with more restrictions, without communicating with the service that created the token.

With that, you could have a token carried along with a serie of requests between microservices, with the token reducing its rights as it goes deeper in the system. Or you could get a token from, say, a git repository hosting service, and attenuate it to just the set of rights needed for usage in CI.
Offline attenuation unlocks powerful delegation patterns, without needing to support them directly in the origin service.

<img src="/img/token_disambiguation.jpg" style="width: 100%" />

## Biscuit is a policy language

Authorization policies are written in a logic language derived from [Datalog](https://en.wikipedia.org/wiki/Datalog). Logic languages are well suited for authorization, because they can represent complex relations between elements (like roles, groups, hierarchies) concisely, and efficiently explore and combine multiple rules.
Biscuit's authorization rules can be provided by the authorizer's side, but also by the token: while it can carry data, it can also contain "checks", conditions that the request must fulfill to be accepted. This is the main mechanism for attenuation: take an existing token, add a check for the current date (expiration) or the operation (restrict to read only).

Those authorization policies can be hardcoded in your application, but they can also be deerialized at runtime, so you can update them dynamically as needed. Biscuit also comes with a command line application to create and print a token's content, an online playground for Datalog policies, and web assembly components to make frontend tools around policies development.

To sum up, Biscuit provides tools to build a complete, cross platform authorization system:
- a logic language based on Datalog to write authorization policies
- a server side library, available for multiple language, to write authorizers in you applications
- an authorization token, verified by public key cryptography, that supports offline attenuation
- a command line application to crete, print and attenuate tokens
- WebAssembly components to write and debug authorization policies


## Go further

*Contributing:* Find out how to contribute to Biscuit. [Contributing →](../../contributing/how-to-contribute/)

*Get help on Biscuit:* [Help →](../../help/faq/)

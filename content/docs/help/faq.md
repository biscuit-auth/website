+++
title = "FAQ"
description = "Answers to frequently asked questions."
date = 2021-05-01T19:30:00+00:00
updated = 2021-05-01T19:30:00+00:00
draft = false
weight = 30
sort_by = "weight"
template = "docs/page.html"

[extra]
lead = "Answers to frequently asked questions."
toc = true
top = false
+++

## What is Biscuit?

Biscuit is a platform made of three parts:

- a token format;
- a logic language for describing data and authorization policies;
- libraries providing support for creating and parsing tokens as well as evaluating authorization policies in the context of a given token.

## What are the concrete benefits of offline attenuation?

Offline attenuation is a powerful tool when it comes to applying the principle of least power: each action should be carried out with credentials that grant the least amount of access. Ideally, credentials should be only usable for the action they are tied to, nothing else.

This property is easily achievable in an authorization protocol where credentials carry a request signature. This makes them unusable for anything else. The issue is that issuing these credentials require either having access to a secret key, or talking to a service which has access to this secret key. This makes it generally impossible to actually do this in a microservices architecture with several chained service-to-service calls: you don't want secrets to be carried around everywhere, and you don't want every call to depend on a central issuing service.

Offline attenuation particularly shines when it comes to make an existing authorization system evolve. In a greenfield authorization system, it is easy to bake in all the desired properties in the system itself during its design. Once the system is deployed, it becomes way harder to do. Offline attenuation gives you just that: the power of strengthening calls made in an existing system, without changing the authorization protocol itself, or requiring changes to the system architecture by introducing calls to a central token delivery service.

## It's more of a comment than a question; I have found a flaw in biscuit's crypto, the private key is carried in the token.

Offline attenuation in biscuit relies on chaining signed blocks. To this effect, single-use keypairs are used to validate that the blocks are correctly chained. In this scheme, only the authority block is signed with a well-known, multi-use private key, which is never carried in a token. The same applies for external signatures on third-party blocks.

The cryptography of biscuit tokens has been informally checked out by experimented cryptographers and no flaws have been found in the current scheme.

The documentation carries a more detailed [explanation of the cryptography](https://doc.biscuitsec.org/reference/cryptography.html).

## What is your favorite Biscuit recipe?


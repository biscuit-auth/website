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

## How can biscuit be integrated with OAuth and OIDC?

Biscuit is focused on the authorization and delegation side of API access, so it can be used as an OAuth access token. OAuth does not mandate a specific format for the access token.
Refresh tokens work better when they are meant for a single use. In that case, a random string stored in the Authorization Server (in OAuth terms) database will fit the task.
OIDC specifies that identity information is transmitted using JWT, so Biscuit will not be usable in their place.

## Why Datalog?

When searching for a suitable language to write authorization policies, it appeared that logic languages are generally a good fit. Other projects like OPA and Oso came to the same conclusion. Datalog is simple enough to be taught in a few minutes, and its implementation is straightforward, which makes it a good choice for safe authorization.

## Isn't JWT enough?

JWT fits a specific use case: transmitting identity and authorization information from one central service to multiple less trusted services without tampering it. This works well for simple architectures like monoliths, but will soon force some tradeoffs in complexity or safety when used in today's microservices or federate architectures.
It was also specified with a number of pitfalls that created a number of security incidents over the years.

Biscuit builds upon the experience earned building authorization systems with JWT and other tools, takes steps to address their risks, and clearly target the larger systems we are now buiding.

## What is your favorite Biscuit recipe?


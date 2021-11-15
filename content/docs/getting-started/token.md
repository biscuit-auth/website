+++
title = "Bearer token"
description = "Biscuit's bearer token"
date = 2021-05-01T08:20:00+00:00
updated = 2021-05-01T08:20:00+00:00
draft = false
weight = 20
sort_by = "weight"
template = "docs/page.html"

[extra]
lead = "Biscuit's bearer token"
toc = true
top = false
+++

A biscuit token is carried with a request to hold information about its basic rights or add restrictions on which operation is performed. That token supports offline attenuation: a new, valid token can be created from an existing one by adding restrictions (example: expiration date), without first going through the token creation service. It is signed with public key cryptography, which means that any service knowing the public key can verify a token.

The rights and restrictions in the token are written as Datalog, a logic language used in Biscuit for authorization policies.

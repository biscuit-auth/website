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

The Biscuit token can be transported along with a request, in a cookie, authorization header, or any other mean. The token can be stored as binary data, or base64 encoded. It is designed to be small enough for use in most protocols, and fast to verify to keep a low overhead in authorization.

The token holds cryptographically signed data indicating the holder's basic rights, and additional constraints on the request. As an example, the token could define its use for read only operations, or from a specific IP address.

From an existing token, it is possible to create a new token with more restrictions. This is the process of offline attenuation: new validations can be encoded without communication with the token creator, and the token can only be restricted, it will never gain more rights.

example of token attenuation:
- [in Rust](/docs/Usage/rust/#attenuate-a-token)
- [in Haskell](/docs/Usage/haskell/#attenuate-a-token)

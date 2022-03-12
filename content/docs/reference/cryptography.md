+++
title = "Cryptography"
description = "Cryptographic design"
date = 2021-05-01T08:00:00+00:00
updated = 2021-05-01T08:00:00+00:00
draft = false
weight = 10
sort_by = "weight"
template = "docs/page.html"

[extra]
lead = "How Biscuit uses cryptography for attenuation."
toc = true
top = false
+++

Biscuit uses public key cryptography to build its tokens: the private key is
required to create a token, and must be kept safe. The public key can be
distributed, and is needed to verify a token.

Specifically, it uses the [Ed25519 algorithm](https://en.wikipedia.org/wiki/EdDSA).

A public key signature proves that the signed data has not been modified.
So how does Biscuit implement attenuation, where a new valid token can be
created from an existing one?

The token uses a scheme inspired from public key infrastructure, like TLS certificates.
It is made of a list of blocks, each of them containing data, a signature
and a public key. When creating the token, we generate a random key pair.
The root private key is used to sign the data and the new public key.
The token then contains two blocks:
- first block:
  - data
  - new public key
  - signature
- proof block:
  - new private key

<img src="/img/authority.svg" style="width: 100%" />

To verify that token, we need to know the root public key. With that key,
we check the signature of the first block. Then we take the public key
from the first block, and verify that it matches the private key from
the proof block.

## Attenuation

If we have a valid token, to create a new one, we remove the last block
that contains a private key, generate a new random key pair, sign the data
an the new public key, with the private key from the previous token.
The token now contains:
- all the blocks from the previous token except the last one
- new block:
  - data
  - new public key
  - signature
- proof block:
  - new private key

<img src="/img/block1.svg" style="width: 100%" />

To verify that token, we proceed as previously, using the public key from
the current block to check the signature of the next block.

## Sealed tokens

It is possible to seal a token, making sure that it cannot be attenuated
anymore. In that scheme, the proof block is replaced with a signature
of the last data block (including the signature). This proves that we had
access to the last private key.
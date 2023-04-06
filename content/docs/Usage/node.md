+++
title = "NodeJS"
description = "Using the Biscuit-wasm NPM package"
date = 2021-05-01T08:00:00+00:00
updated = 2021-05-01T08:00:00+00:00
draft = false
weight = 20
sort_by = "weight"
template = "docs/page.html"

[extra]
lead = "How to use the Biscuit-wasm NPM package"
toc = true
top = false
+++

The NodeJS version of Biscuit can be found on [Github](https://github.com/biscuit-auth/biscuit-wasm),
and on [NPM](https://www.npmjs.com/package/@biscuit-auth/biscuit-wasm). It wraps the
[Biscuit Rust library](https://github.com/biscuit-auth/biscuit-rust) in WebAssembly, and it
provides both CommonJS and EcmaScript module interfaces.

The methods that can fail (like `Authorizer.authorize()`) will throw an exception, containing a
copy of the [Rust library error](https://docs.rs/biscuit-auth/latest/biscuit_auth/error/enum.Token.html)
deserialized from JSON.

## Install

```sh
npm install @biscuit-auth/biscuit-wasm
```

⚠️ Due to some Wasm side dependencies, Node versions before v19 require the following:

```js
import { webcrypto } from 'node:crypto';

globalThis.crypto = webcrypto;
```

## Create a root key

```js
const { KeyPair } = require('@biscuit-auth/biscuit-wasm');

const root = new KeyPair();
```

## Create a token

```js
const { check, fact, Biscuit, KeyPair } = require('@biscuit-auth/biscuit-wasm');

const builder = Biscuit.builder();
builder.addFact(fact("user(1234)"));
builder.addCheck(check("check if operation(\"read\")"));

const token = builder.build(root.getPrivateKey());
```

## Create an authorizer

```js
const authorizer = token.getAuthorizer();

authorizer.addCode("allow if user(1234); deny if true;");
const acceptedPolicy = authorizer.authorize();
```

## Attenuate a token

```js
const { block } = require('@biscuit-auth/biscuit-wasm');

// restrict to read only
const attenuatedToken = token.appendBlock(block("check if operation(\"read\")"));
```

## Seal a token

```js
const sealedToken = token.sealToken();
```

## Reject revoked tokens

```js
const revocationIds = token.getRevocationIdentifiers();
```

## Query data from the authorizer

```js
const fact = authorizer.query(rule("data($id) <- user($id)"));
```

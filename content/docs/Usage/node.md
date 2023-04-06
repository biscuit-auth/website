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

## Create a root key

```javascript
const {KeyPair} = require('@biscuit-auth/biscuit-wasm');

let root = new KeyPair();
```

## Create a token

```javascript
const {Biscuit, KeyPair} = require('@biscuit-auth/biscuit-wasm');

let builder = Biscuit.builder();
builder.add_authority_fact("user(1234)");
builder.add_authority_check_("check if operation(\"read\");");
    
let token = builder.build(root);
```

## Create an authorizer

```javascript
let authorizer = token.authorizer();

authorizer.add_code("allow if user(1234); deny if true;");
var accepted_policy = authorizer.authorize();
```

## Attenuate a token

```javascript
let block = token.create_block();

// restrict to read only
block.add_check("check if operation(\"read\")");
let attenuated_token = token.append(block);
```

## Seal a token

```javascript
let sealed_token = token.seal();
```

## Reject revoked tokens

TODO

## Query data from the authorizer

TODO

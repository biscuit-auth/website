# NodeJS

The NodeJS version of Biscuit can be found on [Github](https://github.com/biscuit-auth/biscuit-wasm),
and on [NPM](https://www.npmjs.com/package/@biscuit-auth/biscuit-wasm). It wraps the
[Biscuit Rust library](https://github.com/biscuit-auth/biscuit-rust) in WebAssembly, and it
provides both CommonJS and EcmaScript module interfaces.

The methods that can fail (like `Authorizer.authorize()`) will throw an exception, containing a
copy of the [Rust library error](https://docs.rs/biscuit-auth/latest/biscuit_auth/error/enum.Token.html)
deserialized from JSON.

## Install

In `package.json`:

```json
{
    "dependencies": {
        "@biscuit-auth/biscuit-wasm": "0.4.0"
    }
}
```

⚠️ Due to some WASM-side dependencies, NodeJS versions before v19 require the following:

```js
import { webcrypto } from 'node:crypto';
globalThis.crypto = webcrypto;
```

## Create a root key

```javascript
const { KeyPair } = require('@biscuit-auth/biscuit-wasm');

const root = new KeyPair();
```

## Create a token

```javascript
const { biscuit, KeyPair } = require('@biscuit-auth/biscuit-wasm');

const root = new KeyPair();
const userId = "1234";
// a token can be created from a datalog snippet
const biscuitBuilder = biscuit`
  user(${userId});
  check if resource("file1");
`;

// facts, checks and rules can be added one by one on an existing builder.
for (let right of ["read", "write"]) {
    biscuitBuilder.addFact(fact`right(${right})`);
}

const token = builder.build(root);
console.log(token.toBase64());
```

## Authorize a token

```javascript
const { authorizer, Biscuit } = require('@biscuit-auth/biscuit-wasm');

const token = Biscuit.fromBase64("<base64 string>");

const userId = "1234";
const auth = authorizer`
  resource("file1");
  operation("read");
  allow if user(${userId}), right("read");
`;
auth.addToken(token);

// returns the index of the matched policy. Here there is only one policy,
// so the value will be `0`
const acceptedPolicy = authorizer.authorize();

// the authorization process is restricted to protect from DoS attacks. The restrictions can be configured
const acceptedPolicyCustomLimits = authorizer.authorizeWithLimits({
  max_facts: 100, // default: 1000
  max_iterations: 10, // default: 100
  max_time_micro: 100000 // default: 1000 (1ms)
});
```

## Attenuate a token

```javascript
const { block, Biscuit } = require('@biscuit-auth/biscuit-wasm');

const token = Biscuit.fromBase64("<base64 string>");

// restrict to read only
const attenuatedToken = token.append(block`check if operation("read")`);
console.log(attenuatedToken.toBase64());
```

## Seal a token

A sealed token cannot be attenuated further.

```javascript
const { Biscuit } = require('@biscuit-auth/biscuit-wasm');

const token = Biscuit.fromBase64("<base64 string>");

const sealedToken = token.sealToken();
```

## Reject revoked tokens


```javascript
const { Biscuit } = require('@biscuit-auth/biscuit-wasm');

const token = Biscuit.fromBase64("<base64 string>");

// revocationIds is a list of hex-encoded revocation identifiers,
// one per block
const revocationIds = token.getRevocationIdentifiers();

if (containsRevokedIds(revocationIds)) {
    // trigger an error
}

```

## Query data from the authorizer

```javascript
const { authorizer, rule, Biscuit } = require('@biscuit-auth/biscuit-wasm');

const token = Biscuit.fromBase64("<base64 string>");

const userId = "1234";
const auth = authorizer`
  resource("file1");
  operation("read");
  allow if user(${userId}), right("read");
`;
auth.addToken(token);

// returns the index of the matched policy. Here there is only one policy,
// so the value will be `0`
const acceptedPolicy = auth.authorize();

const results = auth.query(rule`u($id) <- user($id)`);
console.log(results.map(fact => fact.toString()));
```

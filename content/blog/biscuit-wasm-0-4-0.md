+++
title = "Biscuit WASM 0.4.0"
description = "Version 0.4.0 of the javascript biscuit implementation has been released"
date = 2023-04-26T00:09:00+02:00
draft = false
template = "blog/page.html"

[taxonomies]
authors = ["clementd"]

[extra]
lead = "Biscuit support in javascript has been updated, with full support for third-party blocks, nice datalog integration and support for protecting express apps"
+++

Biscuit is a specification for a cryptographically verified authorization token
supporting offline attenuation, and a language for authorization policies based on Datalog.
It is used to build decentralized authorization systems, such as microservices architectures,
or advanced delegation patterns with user facing systems.

Following the stable release of [biscuit-rust][biscuit-rust], we are pleased to announce that [biscuit-wasm][biscuit-wasm] has been released as well.

## Biscuit-wasm

Javascript support for biscuit tokens is provided through webassembly: [biscuit-rust][biscuit-rust] is compiled to this portable format, which can be then executed both by nodejs and browsers. The goal of [biscuit-wasm][biscuit-wasm] is to provide a nice, ergonomic API to allow manipulating biscuits from javascript.

[biscuit-wasm][biscuit-wasm] is shipped with [typescript declaration files][ts-decl] in order to provide auto-completion in modern editors.

## Datalog tagged templates

Javascript provides a powerful mechanism to embed snippets of non JS code inside a JS codebase: [tagged templates][tagged-templates]. They are commonly used when working with HTML, CSS or SQL within a JS file.

Biscuit-wasm takes full advantage of tagged templates to provide a convenient way to embed datalog snippets in JS applications. It also takes care of injecting dynamic values inside
datalog statements, to avoid any risk of datalog injection.

```js
const userId = "1234";
const auth = authorizer`
  time(${new Date()});
  allow if user(${userId})
`;
```

The following tagged templates are available:

- `authorizer`
- `biscuit`
- `block`
- `fact`
- `rule`
- `check`
- `policy`

Parameter injection works out of the box with the following javascript types:

- booleans;
- strings;
- numbers;
- date objects;
- `Uint8Array`s (will turn into a `hex:` byte array value);
- `PublicKey`s (in `trusting` annotations, see [third-party blocks][third-party-blocks]).

**Parameter injection is the only safe way to inject javascript values inside a datalog snippet. Don't use string concatenation, as it allows datalog injection attacks.**

## Securing express applications

One of the most common use-cases for biscuit is securing APIs. [biscuit-wasm][biscuit-wasm] provides support for securing [express][express] applications through a dedicated middleware.

This integration allows both per-endpoint authorizer policies, as well as global policies applied to every endpoint. This is convenient to provide common facts and rules without having to duplicate them in every endpoint.
All authorizer snippets can have access to the incoming request.

```js
import express from "express";
import {authorizer, middleware, PublicKey} from "@biscuit-auth/biscuit-wasm";

const app = express();

const rootKey = PublicKey.fromString("b88bb092a9ec5a4bf6825520ae9d79b6a5a41003b2a611ca6b1c584d7eaaa470");

const protect = middleware({
  publicKey: rootKey,
  fallbackAuthorizer: () => authorizer`time(${new Date()})`
});

app.get(
  "/protected/:dog",
  protect(req => authorizer`allow if right(${req.params.dog}, "read");`),
  (req, res) => {
    const user = req.biscuit.authorizer.query(rule`u($id) <- user($id);`)[0];
    …
  }
);

app.listen(3000, () => {
  console.log("Application started");
});
```

## Next steps

We are eager to see how [biscuit-wasm][biscuit-wasm] is used in the wild. We are still waiting on more user feedback to issue a proper 1.0, but it's now in a shape where we feel it can be tried out by the wider community.

Documentation is lagging a bit behind for now, don't hesitate to reach out if you want to help!

[biscuit-rust]: https://crates.io/crates/biscuit-auth
[biscuit-wasm]: https://npmjs.com/package/@biscuit-auth/biscuit-wasm
[ts-decl]: https://www.typescriptlang.org/docs/handbook/declaration-files/introduction.html
[third-party-blocks]: https://www.biscuitsec.org/blog/third-party-blocks-why-how-when-who/
[tagged-templates]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Template_literals#tagged_templates
[express]: https://expressjs.com/

+++
title = "Biscuit 3.0"
description = "Version 3.0.0 of the biscuit reference implementation has been released"
date = 2023-03-29T00:09:00+02:00
draft = false
template = "blog/page.html"

[taxonomies]
authors = ["clementd"]

[extra]
lead = "The reference implementation of rust has been released, will full support for the latest spec additions"
+++

## The biscuit specification and the library ecosystem

Biscuit is published as specification, along with several implementations. Amongst them, [`biscuit-rust`](todo) is the reference implementation.
It is used when programming in rust, but it also powers [`biscuit-wasm`](todo) which provides support for javascript applications (both client-side
and server-side), [`biscuit-web-components`](todo) which provides in-browser interactive tooling.

## Biscuit v3

Motivated by [third-party blocks](todo), a new specification version was released. In addition to third-party blocks, a few other changes have been
included in the new version.

- support for `check all`
- support for bitwise operators
- support for `!=`
- support for authorizer snapshots

### A word on biscuit versions

The currently supported biscuit versions are `v2` and `v3`. Those two versions are compatible and `v3` is opt-in: if you don't use any new feature from
biscuit v3, the generated tokens will work with implementations only supporting `v2` biscuits. Of course, `v2` biscuits continue being supported by new
implementations. It is even possible to attenuate a `v2` biscuit with `v3` features.

## `biscuit-rust-3.0.0`

The last stable release of `biscuit-rust` was `v2.2.0`, published ten months ago. While support for third-party blocks and other `v3` features make for
the bulk of the changes, the library itself has been improved. The biggest improvement would be the datalog macros (introduced in `v2.2.0`) which are
now covering all use-cases in a performant fashion.

```rust
let user_id = "1234";
let expiration = SystemTime::now() + Duration::from_secs(86400);
let mut authority = biscuit!(r#"
  user({user_id});
  check if time($time), $time < {expiration};
  "#
);

let rights = ["read", "write"];
for right in rights {
  biscuit_merge!(&mut authority, r#"
    right({right});
  "#);
}
```

## `biscuit-wasm-0.4.0`

In addition to the `biscuit-rust` release, a release of `biscuit-wasm` is planned for the upcoming days. `biscuit-wasm-0.4.0` will bundle all of the
improvements from `biscuit-rust-3.0.0` and will also pack JS-specific improvements. The most important one is the JS counterpart to datalog macros in
rust: tagged templates. 

```javascript
let user_id = "1234";
let authority =
  biscuit`user(${user_id});
          check if time($time), $time < ${new Date("2023-03-29T09:00:00Z")}`;
for (let right of ["read", "write"]) {
   authority.add_fact(fact`right(${right})`);  
}

let token = authority.build(secretKey);
let auth = authorizer`time(${new Date()}); allow if user($u);`;
auth.authorize();
let facts = auth.query(rule`u($id) <- user($id)`);
```

## Other ongoing projects

While biscuit-rust and biscuit-wasm are where most of the work happens, there are a few areas where things have happened.

- [tree-sitter-biscuit](todo) provides tree-sitter based editor support for biscuit datalog (tree-sitter is available in emacs, neovim, helix);
- [biscuit-cli](todo) allows manipulating and inspecting biscuits on the command line;
- [biscuit-dotnet](todo) has been released recently, providing biscuit support to the dotnet platform;
- [biscuit-web-components](todo) provide an embeddable editor and token inspector.

## A word on [Outscale](https://outscale.com)

I ([Clément Delafargue](todo)) have joined [Outscale](https://outscale.com) (a French cloud provider) last week, and working on biscuit is now a part of my job,
since outscale is investing in biscuit. That's great news since it allows me to dedicate way more time to biscuit. Some of my coworkers will also contribute to
biscuit, so we are planning to carry out improvements in several areas, including tutorials and documentation.

## Let's have a chat!

Please come have a chat on [our matrix room](https://matrix.to/#/!MXwhyfCFLLCfHSYJxg:matrix.org) if you have questions about biscuit. There is a lot to discover!

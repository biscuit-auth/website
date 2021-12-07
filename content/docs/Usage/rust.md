+++
title = "Rust"
description = "Using the Biscuit Rust crate"
date = 2021-05-01T08:00:00+00:00
updated = 2021-05-01T08:00:00+00:00
draft = false
weight = 10
sort_by = "weight"
template = "docs/page.html"

[extra]
lead = "How to use the Biscuit Rust crate"
toc = true
top = false
+++

The Rust version of Biscuit can be found on [Github](https://github.com/biscuit-auth/biscuit-rust),
[crates.io](https://crates.io/crates/biscuit-auth) and on [docs.rs](https://docs.rs/biscuit-auth).

## Install

In `Cargo.toml`:

```toml
biscuit-auth = "2.0"
```

## Create a root key

```rust
use biscuit_auth::KeyPair;

let root_keypair = KeyPair::new();
```

## Create a token

```rust

use biscuit_auth::{Biscuit, KeyPair, error};

fn create_token(root: &KeyPair) -> Result<Biscuit, error::Token> {
    let mut builder = Biscuit::builder(root);
    builder.add_authority_fact(r#"user("1234")"#)?;
    builder.add_authority_check_(r#"check if operation("read");"#)?;
    
    builder.build()
}
```

## Create an authorizer

```rust
use biscuit_auth::{Biscuit, error};

fn authorize(token: &Biscuit) -> Result<(), error::Token> {
    let mut authorizer = token.authorizer()?;

    // add a time($date) fact with the current date
    authorizer.set_time()?;
    authorizer.add_operation("read")?;
    authorizer.allow()?;

    authorizer.authorize()?;

    Ok(())
}
```

## Attenuate a token

```rust
use biscuit_auth::{Biscuit, error, builder::Check};
use std::time::{Duration, SystemTime};

fn attenuate(token: &Biscuit) -> Result<Biscuit, error::Token> {
    let mut builder = token.create_block();

    builder.add_check("check if time($time), $time < $ttl")?;
    builder.set("ttl", System::now() + Duration::from_secs(60))?;
    
    token.append(builder)
}
```

## Seal a token

```rust
let sealed_token = token.seal()?;
```

## Reject revoked tokens

TODO

## Query data from the authorizer

TODO
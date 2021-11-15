+++
title = "Command line"
description = "Using the Biscuit command line application"
date = 2021-05-01T08:00:00+00:00
updated = 2021-05-01T08:00:00+00:00
draft = false
weight = 10
sort_by = "weight"
template = "docs/page.html"

[extra]
lead = "How to use the Biscuit command line application"
toc = true
top = false
+++

## Install

### From source

```
cargo install biscuit-cli
```

### From pre-built packages


## Create a root key

```rust
use biscuit_auth::KeyPair;

let root_keypair = KeyPair::new();
```

## Create a token

TODO

## Create an authorizer

TODO

## Attenuate a token

TODO

## Seal a token

TODO
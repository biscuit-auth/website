+++
title = "Biscuit 2.1 release"
description = "Introducing Biscuit 2.1"
date = 2022-03-26T09:00:00+01:00
updated = 2022-03-26T09:00:00+01:00
draft = false
template = "blog/page.html"

[taxonomies]
authors = ["geal", "clementd"]

[extra]
lead = "We are delighted (again) to announce the release of Biscuit at version 2.1!"
+++

After the release of biscuit v2.0, we’ve noticed a small discrepancy between the spec and most implementations.
While small, this discrepancy was annoying enough to cause issues: it meant that the same serialized biscuit
could have different textual representations when read from `biscuit-haskell` or `biscuit-rust`. A quick fix would
have been to align the spec to the reference implementation and move on, but (after discussing it with the biscuit
early adopters, we decided to take this opportunity to ship a couple breaking changes that had not made it in biscuit
2.0.

After discussing with early biscuit adopters, we felt these breaking changes were important enough to be shipped immediately,
while biscuit v2.0 deployment is still limited.

## Block scoping

One of the big changes in biscuit v2.0 was the scoped execution: each datalog query would only see facts produced from
the previous blocks. While this is generally safe, it opens the door to subtle issues: it sucessfully prevents a block
from extending a token's rights, but it still lets a block prevent attenuation in a non-obvious way: for example, a
block defining `time(2000-01-01T00:00:00Z);` will effectively disable all TTL checks from following blocks.

To avoid this kind of issues, we decided to enforce a stronger default: each block only sees itself and authority. This way,
each block is completely isolated for other blocks, and only trusts the authority when it comes to producing new facts.

### Configurable scope

While we feel that the new default is better in almost every case, we still see a use for the previous scoping rules. So while
the defaults have changed, we have a very precise roadmap for adding it back, in an opt-in way.

The work done on third-party blocks nicely encapsulates configurable scoping roles in a way that allows to select the previous
behaviour. The scope-selecting part has been informally specified and implemented, so we're very confident it will ship soon.
More general work on third-party blocks is well underway with a working implementation and an informal spec. We're ironing out
the last details before proposing a proper spec update. All test suites pass with these new features, so we're very confident about
rolling it out without disrupting existing tokens.

## Symbols

### New default symbol table

The default symbol table is one of the tricks used by biscuit to reduce token sizes. All strings in a biscuit are not
stored directly as strings, but rather as references pointing to a table of strings. This way, each value appears only
once in a token, even if it is repeated. Common strings, (such as `time`, `right`, `read`, …)
are bound to show up in most tokens.
Making them part of the libs allows us to remove it from the token symbol table, further reducing its size.

The default symbol table was the only part of the spec that had not been changed in v2.0. As such, it was still linked
to now-outdated concepts (`ambient`, `authority`, …) and did not cover a lot of things. So we took this opportunity to
remove outdated values, and to put more things in it. It's relatively cheap to put a dozen more values in the library,
while it can help keeping tokens smaller.

### Symbol offsets

Symbols are referenced by their position in the table. Default symbols started at 0, and block-defined symbols started after
that. There was no way to differenciate between a default symbol and a block-defined one in a token. So we've reserved the
ids 0 to 1024 to default symbols. This will allow us to do fancier things with symbol tables in the future without having
to worry about invalidating old tokens.


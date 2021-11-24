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


## Create a key pair

```
$ # this will output the keypair, you can then copy/paste the components
$ biscuit keypair
> Generating a new random keypair
> Private key: 4aa4bae701c6eb05cfe0bdd68d5fab236fc0d0d3dcb2a9b582a0d87b23e04500
> Public key: 687b536c502f10f5978eee2d0c04f2869d15cf7858983dc50b6729b15e203809

$ # this will save the private key to a file so you can use it later
$ biscuit keypair --only-private-key > private-key-file
```

### Generate a public key from a private key

```
$ biscuit keypair --from-private-key-file private-key-file --only-public-key
> 94cbe231b05dac8ae556c39a3cdc3d12103ad9ed5500eda6098c60e6672bf858
```

## Create a token

```
$ # this will open your text editor and let you type in the authority block as datalog
$ biscuit generate --private-key-file private-key-file
> ChcIADgBQhEKDwgEEgIIABIHIgVmaWxlMRoglMviMbBdrIrlVsOaPNw9EhA62e1VAO2mCYxg5mcr-FgiRAogKAZh5JjRh6n3UTQIVlptzWsAhj92UaOjWZQOVYYqaTASIFG7bXx0Y35LjRWcJHs7N6CAEOBJOuuainDg4Rg_S8IG

$ # this will generate the token directly 
$ echo 'right("file1");' | biscuit generate --private-key-file pkf -
ChcIADgBQhEKDwgEEgIIABIHIgVmaWxlMRoglMviMbBdrIrlVsOaPNw9EhA62e1VAO2mCYxg5mcr-FgiRAogCCirktOm6gYKHHnjyQ49L7u2YOyxfi9gPQ0q_5_bRXASIBeYUocb2BHGgS3-GJCmgq1sk26YH439UhvnsScrXz4H

```

## Verify a token

```
$ biscuit inspect --raw-input biscuit-file.bc --public-key acdd6d5b53bfee478bf689f8e012fe7988bf755e3d7c5152947abc149bc20189 --verify-with 'time(2021-11-01T14:44:44Z); check if false; deny if true;'`
Authority block:
== Datalog ==
right("file1", "read");
right("file2", "read");

== Revocation id ==
893ff2daf44325f05849f581de561732094f14223d724202ce2f3d4058cead2ba238e4ef3a6b18f076f155e5e21ec30eded28f98d29979a39eb7f72da128a404

==========

Block n°1:
== Datalog ==
valid_date("file1") <- time($0), resource("file1"), $0 <= 2030-12-31T12:59:59+00:00;
valid_date($1) <- time($0), resource($1), $0 <= 1999-12-31T12:59:59+00:00, !["file1"].contains($1);
check if valid_date($0), resource($0);

== Revocation id ==
3189fe4ccec73777fcb0a63fb497c4391bc967c1cc02ec409ae19e7e30fd2bfeb2c309e67c615bcae986a0de15a1a21b5623ccdab5afe36c11c539ac7e475202

==========

✅ Public key check succeeded 🔑
❌ Authorizer check failed 🛡️
The following checks failed:
Authorizer check: check if false
Block 1 check: check if valid_date($0), resource($0)
```

## Attenuate a token

```
# this will create a new biscuit token with the provided block appended
$ biscuit attenuate biscuit-file --block 'check if time($0), $0 <= 2021-07-29T14:06:43+00:00;'
> ChcIADgBQhEKDwgEEgIIABIHIgVmaWxlMRJACAESBXF1ZXJ5EgR0aW1lEgEwOAFSKgooCgIIBxIKCAgSAggBEgIQCRoWCgQKAhAJCggKBiiU7IqIBgoEGgIIAhoglMviMbBdrIrlVsOaPNw9EhA62e1VAO2mCYxg5mcr-FgaIM7CFNnvFB-SeN-VhpPRtZJnUzFM918XulzU8OL1pIc7ImYKIAgoq5LTpuoGChx548kOPS-7tmDssX4vYD0NKv-f20VwCiA-zkpZZjA5vLa-8XL8p6oXvf5A-rUCIcHOyPWR3aogdhIgzB0tA9eSatJU0NiQnQW7HgSr0fjnQqJ4ccKHZlrj-w4=
```

## Seal a token

TODO

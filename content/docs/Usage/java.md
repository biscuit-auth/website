+++
title = "Rust"
description = "Using the Biscuit Java library"
date = 2021-05-01T08:00:00+00:00
updated = 2021-05-01T08:00:00+00:00
draft = false
weight = 20
sort_by = "weight"
template = "docs/page.html"

[extra]
lead = "How to use the Biscuit Java library"
toc = true
top = false
+++

The Java version of Biscuit can be found on [Github](https://github.com/CleverCloud/biscuit-java),
and [maven](https://search.maven.org/artifact/com.clever-cloud/biscuit-java).

## Install

In `pom.xml`:

```toml
<dependency>
    <groupId>com.clever-cloud</groupId>
    <artifactId>biscuit-java</artifactId>
    <version>2.0.0</version>
    <type>jar</type>
</dependency>
```

## Create a root key

```java
public KeyPair root() {
    return new KeyPair();
}
```

## Create a token

```java
public Either<Error, Biscuit> createToken(KeyPair root) {
    com.clevercloud.biscuit.token.builder.Biscuit builder = Biscuit.builder(root);

    Either<Error, Void> res = builder.add_authority_fact("user(\"1234\")");
    if(res.isLeft()) {
        Error e = res.getLeft();
        return Left(e);
    }

    res = builder.add_authority_check("check if operation(\"read\")");
    if(res.isLeft()) {
        Error e = res.getLeft();
        return Left(e);
    }

    return builder.build();
}
```

## Create an authorizer

```java
public Either<Error, Long> authorize(KeyPair root, byte[] serializedToken) throws NoSuchAlgorithmException, SignatureException, InvalidKeyException {
    Either<Error, Biscuit> res = Biscuit.from_bytes(serializedToken, root.public_key());
    if(res.isLeft()) {
        Error e = res.getLeft();
        return Left(e);
    }

    Biscuit token = res.get();

    Either<Error, Authorizer> authorizerRes = token.authorizer();
    if(authorizerRes.isLeft()) {
        Error e = authorizerRes.getLeft();
        return Left(e);
    }

    Authorizer authorizer = authorizerRes.get();
    Either<Error, Void> addRes = authorizer.add_fact("resource(\"/folder1/file1\")");
    if(addRes.isLeft()) {
        Error e = res.getLeft();
        return Left(e);
    }

    addRes = authorizer.add_fact("operation(\"read\")");
    if(addRes.isLeft()) {
        Error e = res.getLeft();
        return Left(e);
    }

    authorizer.allow();

    return authorizer.authorize();
}
```

## Attenuate a token

```java
public Either<Error, Biscuit> attenuate(KeyPair root, byte[] serializedToken) throws NoSuchAlgorithmException, SignatureException, InvalidKeyException {
    Either<Error, Biscuit> res = Biscuit.from_bytes(serializedToken, root.public_key());
    if(res.isLeft()) {
        Error e = res.getLeft();
        return Left(e);
    }

    Biscuit token = res.get();
    Block block = token.create_block();
    Either<Error, Void> addRes = block.add_check("check if operation(\"read\")");
    if(addRes.isLeft()) {
        Error e = res.getLeft();
        return Left(e);
    }

    return token.attenuate(block);
}
```

## Seal a token

```java
Either<Error, byte[]> sealed_token = token.seal();
```

## Reject revoked tokens

The `revocation_identifiers` method returns the list of revocation identifiers as byte arrays.

```java
List<byte[]> revocation_ids = token.revocation_identifiers();
```

## Query data from the authorizer

The `query` method takes a rule as argument and extract the data from generated facts as tuples.

```java
public Either<Error, Set<Fact>> query(Authorizer authorizer) {
       return authorizer.query("data($name, $id) <- user($name, $id)");
    }
```

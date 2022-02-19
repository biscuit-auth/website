+++
title = "Go"
description = "Using the Biscuit Go library"
date = 2021-05-01T08:00:00+00:00
updated = 2021-05-01T08:00:00+00:00
draft = false
weight = 20
sort_by = "weight"
template = "docs/page.html"

[extra]
lead = "How to use the Biscuit Go library"
toc = true
top = false
+++

The Go version of Biscuit can be found on [Github](https://github.com/biscuit-auth/biscuit-go).

## Install

In `go.mod`:

```toml
require(
    github.com/biscuit-auth/biscuit-go v1.0.0
)
```

## Create a root key

```go
func CreateKey() (ed25519.PublicKey, ed25519.PrivateKey) {
	rng := rand.Reader
	publicRoot, privateRoot, _ := ed25519.GenerateKey(rng)
	return publicRoot, privateRoot
}
```

## Create a token

```go
func CreateToken(root *ed25519.PrivateKey) (*biscuit.Biscuit, error) {
	builder := biscuit.NewBuilder(*root)

	fact, err := parser.FromStringFact(`user("1234")`)
	if err != nil {
		return nil, fmt.Errorf("failed to parse authority facts: %v", err)
	}
	err = builder.AddAuthorityFact(fact)
	if err != nil {
		return nil, fmt.Errorf("failed to add authority facts: %v", err)
	}

	check, err := parser.FromStringCheck(`check if operation("read")`)
	if err != nil {
		return nil, fmt.Errorf("failed to parse authority checks: %v", err)
	}
	err = builder.AddAuthorityCheck(check)
	if err != nil {
		return nil, fmt.Errorf("failed to add authority checks: %v", err)
	}

	token, err := builder.Build()
	if err != nil {
		return nil, fmt.Errorf("failed to build biscuit: %v", err)
	}

	return token, nil
}
```

## Create an authorizer

```go
func Authorize(token *biscuit.Biscuit, root *ed25519.PublicKey) error {
	authorizer, err := token.Authorizer(*root)
	if err != nil {
		return fmt.Errorf("failed to create verifier: %v", err)
	}

	fact1, err := parser.FromStringFact(`resource("/a/file1.txt")`)
	if err != nil {
		return fmt.Errorf("failed to parse verifier fact: %v", err)
	}
	authorizer.AddFact(fact1)

	fact2, err := parser.FromStringFact(`operation("read")`)
	if err != nil {
		return fmt.Errorf("failed to parse verifier fact: %v", err)
	}
	authorizer.AddFact(fact2)

	policy, err := parser.FromStringPolicy(`allow if resource("/a/file1.txt")`)
	if err != nil {
		return fmt.Errorf("failed to parse verifier policy: %v", err)
	}
	authorizer.AddPolicy(policy)

	return authorizer.Authorize()
}
```

## Attenuate a token

```go
func Attenuate(serializedToken []byte, root *ed25519.PublicKey) ([]byte, error) {
	token, err := biscuit.Unmarshal(serializedToken)
	if err != nil {
		return nil, fmt.Errorf("failed to deserialize biscuit: %v", err)
	}

	blockBuilder := token.CreateBlock()

	check, err := parser.FromStringCheck(`check if resource($file), operation($permission), ["read"].contains($permission)`)
	if err != nil {
		return nil, fmt.Errorf("failed to parse check: %v", err)
	}
	err = blockBuilder.AddCheck(check)
	if err != nil {
		return nil, fmt.Errorf("failed to add block check: %v", err)
	}

	rng := rand.Reader
	token2, err := token.Append(rng, blockBuilder.Build())
	if err != nil {
		return nil, fmt.Errorf("failed to append: %v", err)
	}

	return token2.Serialize()
}
```

## Seal a token

```go
rng := rand.Reader
return token.Seal(rng)
```

## Reject revoked tokens

The `Biscuit::RevocationIds` method returns the list of revocation identifiers as byte arrays.

```go
identifiers := token.RevocationIds();
```

## Query data from the authorizer

The `Authorizer::Query` method takes a rule as argument and extract the data from generated facts as tuples.

```go
func Query(authorizer biscuit.Authorizer) (biscuit.FactSet, error) {
	rule, err := parser.FromStringRule(`data($name, $id) <- user($name, $id`)
	if err != nil {
		return nil, fmt.Errorf("failed to parse check: %v", err)
	}

	return authorizer.Query(rule)
}
```
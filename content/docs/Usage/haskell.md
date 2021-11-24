+++
title = "Haskell"
description = "Using the Biscuit Haskell package"
date = 2021-05-01T08:00:00+00:00
updated = 2021-05-01T08:00:00+00:00
draft = false
weight = 10
sort_by = "weight"
template = "docs/page.html"

[extra]
lead = "How to use the Biscuit Haskell package"
toc = true
top = false
+++

## Install

In the cabal file:

```
biscuit-haskell ^>= 0.2
```

## Create a key pair

```haskell
import Auth.Biscuit

main :: IO ()
main = do
  secretKey <- generateSecretKey
  let publicKey = toPublic secretKey
  -- will print the hex-encoded secret key
  print $ serializeSecretKeyHex secretKey
  -- will print the hex-encoded public key
  print $ serializePublicKey publicKey
```

## Create a token

```haskell
{-# LANGUAGE QuasiQuotes #-}
import Auth.Biscuit

myBiscuit :: SecretKey -> Biscuit
myBiscuit secretKey =
  -- datalog blocks are declared inline and are parsed
  -- at compile time
  mkBiscuit secretKey [block|
    user("1234");
    check if operation("read");
  |]
```

## Authorize a token

```haskell
{-# LANGUAGE QuasiQuotes #-}
import Auth.Biscuit
import Data.Time (getCurrentTime)

myCheck :: Biscuit p Verified -> IO Bool
myCheck b = do
  now    <- getCurrentTime
  -- datalog blocks can reference haskell variables with the
  -- special `${}` syntax. This allows dynamic datalog generation
  -- without string concatenation
  result <- authorizeBiscuit b [authorizer|
                                 time(${now});
                                 operation("read");
                                 allow if true;
                               |]
  case result of
    Left a  -> pure False
    Right _ -> pure True
```

## Attenuate a token

```haskell
{-# LANGUAGE QuasiQuotes #-}
import Auth.Biscuit
import Data.Time (UTCTime)

-- only `Open` biscuits can be attenuated
addTTL :: UTCTime -> Biscuit Open c -> IO (Biscuit Open c)
addTTL ttl b =
  addBlock [block|check if time($time), $time < ${ttl}; |] b
```

## Seal a token

```haskell
import Auth.Biscuit

-- `Open` biscuits can be sealed. The resulting biscuit
-- can't be attenuated further
sealBiscuit :: Biscuit Open c -> Biscuit Sealed c
sealBiscuit b = seal b
```

## Query data from the authorizer

(filters)

TODO

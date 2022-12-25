+++
title = "Haskell"
description = "Using the Biscuit Haskell package"
date = 2021-05-01T08:00:00+00:00
updated = 2021-05-01T08:00:00+00:00
draft = false
weight = 20
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
biscuit-haskell ^>= 0.2.1
```

## Create a key pair

```haskell
import Auth.Biscuit

main :: IO ()
main = do
  secretKey <- newSecret
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

myBiscuit :: SecretKey -> IO (Biscuit Open Verified)
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
                                 time({now});
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
  addBlock [block|check if time($time), $time < {ttl}; |] b
```

## Seal a token

```haskell
import Auth.Biscuit

-- `Open` biscuits can be sealed. The resulting biscuit
-- can't be attenuated further
sealBiscuit :: Biscuit Open c -> Biscuit Sealed c
sealBiscuit b = seal b
```

## Reject revoked tokens

Revoked tokens can be rejected directly during parsing:

```haskell
import Auth.Biscuit

parseBiscuit :: IO Bool
parseBiscuit =  do
  let parsingOptions = ParserConfig
        { encoding = UrlBase64
        , getPublicKey = \_ -> myPublicKey
        -- ^ biscuits carry a key identifier, allowing you to choose the
        -- public key used for signature verification. Here we ignore
        -- it, to always use the same public key
        , isRevoked = fromRevocationList revokedIds
        -- ^ `fromRevocationList` takes a list of revoked ids, but
        -- the library makes it possible to run an effectful check instead
        -- if you don't have a static revocation list
        }
  result <- parseWith parsingOptions encodedBiscuit
  case result of
    Left _ -> False
    Right _ -> True
```

## Query data from the authorizer

The values that made the authorizer succeed are kept around in the
authorization success, and can be queried directly with `getBindings`.

```haskell
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}

import Auth.Biscuit

checkBiscuit :: Biscuit -> IO Text
checkBiscuit b =
  result <- authorizeBiscuit b [authorizer| allow if user($user); |]
  case result of
    Left a  -> throwError …
    Right success ->
      case getSingleVariableValue (getBindings success) "user" of
        Just userId -> pure userId
        -- ^ this will only match if a unique user id is
        -- retrieved from the matched variables
        Nothing -> throwError …
```

You can also provide custom queries that will be run against all the
generated facts.  Be careful, only facts from the _authority block_
and the _authorizer_ are queried; block facts are ignored since they
can't be trusted.

```haskell
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}

import Auth.Biscuit

checkBiscuit :: Biscuit -> IO Text
checkBiscuit b =
  result <- authorizeBiscuit b [authorizer| allow if true; |]
  case result of
    Left a  -> throwError …
    Right success ->
      case getSingleVariableValue (queryAuthorizerFacts success [query|user($user)|]) "user" of
        Just userId -> pure userId
        -- ^ this will only match if a unique user id is
        -- retrieved from the matched variables
        Nothing -> throwError …
```

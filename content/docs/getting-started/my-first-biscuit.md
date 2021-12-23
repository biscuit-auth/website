+++
title = "My first biscuit"
description = "Creating and authorizing a biscuit"
date = 2021-05-01T08:20:00+00:00
updated = 2021-05-01T08:20:00+00:00
draft = false
weight = 11
sort_by = "weight"
template = "docs/page.html"

[extra]
lead = "Creating and authorizing a biscuit"
toc = true
top = false
+++

## Creating a biscuit

Creating a biscuit requires two things:

- a secret key that will allow receiving parties to trust the biscuit contents
- an authority block carrying information (and possibly restrictions)

### Creating a secret key

The secret key can be generated with the biscuit CLI:

```
❯ biscuit keypair
Generating a new random keypair
Private key: 473b5189232f3f597b5c2f3f9b0d5e28b1ee4e7cce67ec6b7fbf5984157a6b97
Public key: 41e77e842e5c952a29233992dc8ebbedd2d83291a89bb0eec34457e723a69526
```

The secret key is used to generate biscuits, while the public key can be distributed to all services who will use biscuits to authorize requests.

### Creating a biscuit token

The most important part of a biscuit is its _authority block_. It contains data that is signed with the secret key, and that can be trusted by receiving parties. The authority block is declared in
_datalog_. Datalog is a declarative logic language that is a subset of Prolog.
A Datalog program contains "facts", which represent data, and "rules", which can generate new facts from existing ones.

In our example, we will create a token that identifies its carrier as a _user_ whose user id is `"1234"`.
To do so, we will create a file named `authority.datalog`, with the following contents:

`authority.datalog`

```
user("1234");
```

This is a datalog _fact_: the fact name is `user`, and it has a single attribute (`"1234"`). Facts can have several attributes, of various types (ints, strings, booleans, byte arrays, dates, sets).

Now we have a secret key and an authority block, we can go ahead and generate a biscuit:

```
❯ biscuit generate --private-key-file key.secret authority.datalog
EoIBChgKBHVzZXIKBDEyMzQYAiIICgYIBxICGAgSJAgAEiDr7M1-FDBN8u7m2BH2GDBZmfyuWTXdsJL9rtW4Ygz_mRpA4poqTRDeY5MxB7jyVjj3sL8wtAh4NI640ANpDKzXgpw0l0ZkZQqxaz_n6QT_Bl1-Ytp5tR6m6DsEkLxrt3GIBSIiCiBZgsoaMn4jXN8-boHthy2IJqADpZlQI5f33-5h5_4ftQ==
```

You can inspect the generated biscuit with `biscuit inspect`

```
❯ biscuit inspect -
Please input a base64-encoded biscuit, followed by <enter> and ^D
EoIBChgKBHVzZXIKBDEyMzQYAiIICgYIBxICGAgSJAgAEiDr7M1-FDBN8u7m2BH2GDBZmfyuWTXdsJL9rtW4Ygz_mRpA4poqTRDeY5MxB7jyVjj3sL8wtAh4NI640ANpDKzXgpw0l0ZkZQqxaz_n6QT_Bl1-Ytp5tR6m6DsEkLxrt3GIBSIiCiBZgsoaMn4jXN8-boHthy2IJqADpZlQI5f33-5h5_4ftQ==
Authority block:
== Datalog ==
user("1234");

== Revocation id ==
e29a2a4d10de63933107b8f25638f7b0bf30b40878348eb8d003690cacd7829c34974664650ab16b3fe7e904ff065d7e62da79b51ea6e83b0490bc6bb7718805

==========

🙈 Public key check skipped 🔑
🙈 Datalog check skipped 🛡️
```

Biscuit also provides web components that let you inspect biscuits in the browser:

<bc-token-printer biscuit="EoIBChgKBHVzZXIKBDEyMzQYAiIICgYIBxICGAgSJAgAEiDr7M1-FDBN8u7m2BH2GDBZmfyuWTXdsJL9rtW4Ygz_mRpA4poqTRDeY5MxB7jyVjj3sL8wtAh4NI640ANpDKzXgpw0l0ZkZQqxaz_n6QT_Bl1-Ytp5tR6m6DsEkLxrt3GIBSIiCiBZgsoaMn4jXN8-boHthy2IJqADpZlQI5f33-5h5_4ftQ==" readonly="true"></bc-token-printer>

## Authorizing a biscuit

Now that we have a biscuit, let's have a look at how a service can _authorize_ a request based on a biscuit.

To do so, the service provides an authorizer, built with:

- _facts_ about the request (current time, resource being accessed, type of the operation)
- _facts_ or _rules_ about access control (ACLs, access matrix)
- _checks_ to apply some restrictions (every check has to pass for the authorization to succeed)
- _policies_, which are tried in order, the first one to match decides if the authorization passes or fails

In our case, we'll assume the token is used for a `write` operation on the `resource1` resource.

_authorizer.datalog_

```
// request-specific data
operation("write");
resource("resource1");
time(2021-12-21T20:00:00Z);

// server-side ACLs
right("1234", "resource1", "read");
right("1234", "resource1", "write");
right("1234", "resource2", "read");
is_allowed($user, $res, $op) <-
  user($user),
  resource($res),
  operation($op),
  right($user, $res, $op);

// the request can go through if the current user
// is allowed to perform the current operation
// on the current resource
allow if is_allowed($user, $resource, $op);
```

There's a bit more happening here: The first three facts give info about the request. Then we have ACLs (they can be declared statically for a small, static user base, or fetched from DB based on the token user).

`is_allowed` is more interesting: it's a _rule_. If, given a user, a resource and an operation, there's a `right` fact that puts them all together, then we know the request can go through.

With all that done, we can go ahead and check our biscuit

```
❯ biscuit inspect - --verify-with-file authorizer.datalog --public-key 41e77e842e5c952a29233992dc8ebbedd2d83291a89bb0eec34457e723a69526
Please input a base64-encoded biscuit, followed by <enter> and ^D
EoIBChgKBHVzZXIKBDEyMzQYAiIICgYIBxICGAgSJAgAEiDr7M1-FDBN8u7m2BH2GDBZmfyuWTXdsJL9rtW4Ygz_mRpA4poqTRDeY5MxB7jyVjj3sL8wtAh4NI640ANpDKzXgpw0l0ZkZQqxaz_n6QT_Bl1-Ytp5tR6m6DsEkLxrt3GIBSIiCiBZgsoaMn4jXN8-boHthy2IJqADpZlQI5f33-5h5_4ftQ==
Authority block:
== Datalog ==
user("1234");

== Revocation id ==
e29a2a4d10de63933107b8f25638f7b0bf30b40878348eb8d003690cacd7829c34974664650ab16b3fe7e904ff065d7e62da79b51ea6e83b0490bc6bb7718805

==========

✅ Public key check succeeded 🔑
✅ Datalog check succeeded 🛡️
```

<bc-token-printer biscuit="EoIBChgKBHVzZXIKBDEyMzQYAiIICgYIBxICGAgSJAgAEiDr7M1-FDBN8u7m2BH2GDBZmfyuWTXdsJL9rtW4Ygz_mRpA4poqTRDeY5MxB7jyVjj3sL8wtAh4NI640ANpDKzXgpw0l0ZkZQqxaz_n6QT_Bl1-Ytp5tR6m6DsEkLxrt3GIBSIiCiBZgsoaMn4jXN8-boHthy2IJqADpZlQI5f33-5h5_4ftQ==" readonly="true" showAuthorizer="true">
  <code class="authorizer">
// request-specific data
operation("write");
resource("resource1");
time(2021-12-21T20:00:00Z);
// server-side ACLs
right("1234", "resource1", "read");
right("1234", "resource1", "write");
right("1234", "resource2", "read");
is_allowed($user, $res, $op) <-
  user($user),
  resource($res),
  operation($op),
  right($user, $res, $op);
// the request can go through if the current user
// is allowed to perform the current operation
// on the current resource
allow if is_allowed($user, $resource, $op);
  </code>
</bc-token-printer>

The CLI checks the biscuit signatures, and then the datalog engine will try to match policies. Here,
it succeeded, and the CLI shows you the policy that matched.

## Attenuating a biscuit

One of biscuit's strengths is the ability to attenuate tokens, restricting their use.
Attenuating a biscuit token is done by appending a block containing a _check_.
Let's attenuate our first token by adding a TTL (Time To Live) check: this way the new
token will only be usable for a given period of time. In the authorizer above, we provided
a `time` fact, that was not used in a policy or a check. We can add a block that will make
sure the token is not used after a certain date.

_block1.datalog_

```
check if time($time), $time <= 2021-12-20T00:00:00Z;
```

The check requires two things to suceed: first, the current time must be declared through the `time()` fact, and the current time must be smaller than `2021-12-20T00:00:00Z`.

We can create a new token by appending this block to our existing token:

```
❯ biscuit attenuate - --block-file 'block1.datalog'
Please input a base64-encoded biscuit, followed by <enter> and ^D
EoIBChgKBHVzZXIKBDEyMzQYAiIICgYIBxICGAgSJAgAEiDr7M1-FDBN8u7m2BH2GDBZmfyuWTXdsJL9rtW4Ygz_mRpA4poqTRDeY5MxB7jyVjj3sL8wtAh4NI640ANpDKzXgpw0l0ZkZQqxaz_n6QT_Bl1-Ytp5tR6m6DsEkLxrt3GIBSIiCiBZgsoaMn4jXN8-boHthy2IJqADpZlQI5f33-5h5_4ftQ==
EoIBChgKBHVzZXIKBDEyMzQYAiIICgYIBxICGAgSJAgAEiDr7M1-FDBN8u7m2BH2GDBZmfyuWTXdsJL9rtW4Ygz_mRpA4poqTRDeY5MxB7jyVjj3sL8wtAh4NI640ANpDKzXgpw0l0ZkZQqxaz_n6QT_Bl1-Ytp5tR6m6DsEkLxrt3GIBRqhAQo3CgVxdWVyeQoEdGltZRgCMiYKJAoCCAkSBggKEgIIChoWCgQKAggKCggKBiCAj_-NBgoEGgIIAhIkCAASIHhqG1rHTCB1u9kXzUhD1d_VhZGqUwPa_su7yOskeDPWGkCavMFzZaDaCv_WrHmHJyECGjW4UjSPEKjLNkxj6zGZYLU78opJ5MOUssfGtWovKlKxOdda5qNDSiU0Rs29oawIIiIKIAtxsWj2z69efzcw4idHb9M9ANr2Gh2lsF31kX0DzfjD
```

You can inspect this new token:

<bc-token-printer biscuit="EoIBChgKBHVzZXIKBDEyMzQYAiIICgYIBxICGAgSJAgAEiDr7M1-FDBN8u7m2BH2GDBZmfyuWTXdsJL9rtW4Ygz_mRpA4poqTRDeY5MxB7jyVjj3sL8wtAh4NI640ANpDKzXgpw0l0ZkZQqxaz_n6QT_Bl1-Ytp5tR6m6DsEkLxrt3GIBRqhAQo3CgVxdWVyeQoEdGltZRgCMiYKJAoCCAkSBggKEgIIChoWCgQKAggKCggKBiCAj_-NBgoEGgIIAhIkCAASIHhqG1rHTCB1u9kXzUhD1d_VhZGqUwPa_su7yOskeDPWGkCavMFzZaDaCv_WrHmHJyECGjW4UjSPEKjLNkxj6zGZYLU78opJ5MOUssfGtWovKlKxOdda5qNDSiU0Rs29oawIIiIKIAtxsWj2z69efzcw4idHb9M9ANr2Gh2lsF31kX0DzfjD" readonly="true"></bc-token-printer>

Now, let's try to check it again (pay special attention to the `time` fact we added in the authorizer)
```
❯ biscuit inspect - --verify-with-file authorizer.datalog --public-key 41e77e842e5c952a29233992dc8ebbedd2d83291a89bb0eec34457e723a69526
Please input a base64-encoded biscuit, followed by <enter> and ^D
EoIBChgKBHVzZXIKBDEyMzQYAiIICgYIBxICGAgSJAgAEiDr7M1-FDBN8u7m2BH2GDBZmfyuWTXdsJL9rtW4Ygz_mRpA4poqTRDeY5MxB7jyVjj3sL8wtAh4NI640ANpDKzXgpw0l0ZkZQqxaz_n6QT_Bl1-Ytp5tR6m6DsEkLxrt3GIBRqhAQo3CgVxdWVyeQoEdGltZRgCMiYKJAoCCAkSBggKEgIIChoWCgQKAggKCggKBiCAj_-NBgoEGgIIAhIkCAASIHhqG1rHTCB1u9kXzUhD1d_VhZGqUwPa_su7yOskeDPWGkCavMFzZaDaCv_WrHmHJyECGjW4UjSPEKjLNkxj6zGZYLU78opJ5MOUssfGtWovKlKxOdda5qNDSiU0Rs29oawIIiIKIAtxsWj2z69efzcw4idHb9M9ANr2Gh2lsF31kX0DzfjD
Authority block:
== Datalog ==
user("1234");

== Revocation id ==
e29a2a4d10de63933107b8f25638f7b0bf30b40878348eb8d003690cacd7829c34974664650ab16b3fe7e904ff065d7e62da79b51ea6e83b0490bc6bb7718805

==========

Block n°1:
== Datalog ==
check if time($time), $time <= 2021-12-20T00:00:00+00:00;

== Revocation id ==
9abcc17365a0da0affd6ac79872721021a35b852348f10a8cb364c63eb319960b53bf28a49e4c394b2c7c6b56a2f2a52b139d75ae6a3434a253446cdbda1ac08

==========

✅ Public key check succeeded 🔑
is_allowed($user, $res, $op) <-
  user($user),
  resource($res),
  operation($op),
  right($user, $res, $op)
❌ Datalog check failed 🛡️
The following checks failed:
[Block(FailedBlockCheck { block_id: 1, check_id: 0, rule: "check if time($time), $time <= 2021-12-20T00:00:00+00:00" })]
```

Here it failed because the date provided in the authorizer (`time(2021-12-21T20:00:00Z)`) is greater
than the expiration date specified in the check (`check if time($time), $time <= 2021-12-20T00:00:00+00:00`).

## Next steps

You can learn more about datalog by following [the datalog tutorial](../datalog/) or reading [the datalog reference](../../datalog/reference/).

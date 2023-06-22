+++
title = "Biscuit Python 0.2.0"
description = "Version 0.2.0 of the python biscuit implementation has been released"
date = 2023-06-22T00:09:00+02:00
draft = false
template = "blog/page.html"

[taxonomies]
authors = ["clementd"]

[extra]
lead = "Biscuit support in python has been released"
+++

Biscuit is a specification for a cryptographically verified authorization token
supporting offline attenuation, and a language for authorization policies based on Datalog.
It is used to build decentralized authorization systems, such as microservices architectures,
or advanced delegation patterns with user facing systems.

Following the stable release of [biscuit-rust][biscuit-rust] and the update of [biscuit-wasm][biscuit-wasm], we are pleased to announce that a first version of [biscuit-python][biscuit-python] has been released as well.

## Biscuit-python

[Biscuit-python][biscuit-python] is available on [pypi](https://pypi.org), pre-compiled for several GNU/Linux distributions, MacOS (x86 and Apple Silicon) and windows, as well as a source distribution.

```sh
pip install biscuit-python
```

A dedicated documentation website is available: <https://python.biscuitsec.org>. It features detailed examples and a complete API reference.

[Biscuit-python][biscuit-python] provides a pythonic layer on top of [biscuit-rust][biscuit-rust]: token parsing, datalog parsing, datalog evaluation are handled by the rust library.

The current library grew out of a proof-of-concept started by [Josh Wright](https://github.com/JshWright).

## A few bites of [biscuit-python][biscuit-python]

When working with biscuit, most of the work is about manipulating datalog snippets. Same as with SQL, manually building datalog snippets by concatenating strings is discouraged, as it can be the cause of security issues through injections.

All biscuit libraries provide a way to bind parameters within datalog by referencing values from the host language, and [biscuit-python][biscuit-python] is no exception:

```python
from biscuit_auth import Authorizer, Biscuit, BiscuitBuilder, Fact, PrivateKey, PublicKey, Rule
from datetime import datetime, timedelta, timezone

# you can start with a single datalog snippet
builder = BiscuitBuilder("""
  user({user_id});
  check if time($time), $time < {expiration};
  """,
  { 
    'user_id': '1234',
    # datetimes are supported if they have an explicit timezone
    'expiration': datetime.now(tz = timezone.utc) + timedelta(days = 1)
  }
)

# facts can be dynamically added
for file in ['file1', 'file2']:
  builder.add_fact(Fact("""right({file}, "read")""", { 'file': file}))

token = builder.build(PrivateKey.from_hex("23d9d45b32899eefd4cde9a2caecdd41f0449c95ee1e4c6b53ef38cb957dd690")).to_base64()

print(token)

authorizer = Authorizer("""
  time({time});
  allow if user($u), right({file}, "read");
  """,
  {
    'time': datetime.now(tz = timezone.utc),
    'file': 'file1'
  })

parsed = Biscuit.from_base64(token, PublicKey.from_hex("9e124fbb46ff99a87219aef4b09f4f6c3b7fd96b7bd279e38af3ef429a101c69"))

print(parsed)

authorizer.add_token(Biscuit.from_base64(token, PublicKey.from_hex("9e124fbb46ff99a87219aef4b09f4f6c3b7fd96b7bd279e38af3ef429a101c69")))

authorizer.authorize()

user = authorizer.query(Rule("user($user) <- user($user)"))
print(user[0].terms[0])
```

## Next steps

[Biscuit-python][biscuit-python] is not yet at feature parity with biscuit-rust and biscuit-wasm. Since it is based on biscuit-rust, it is more a matter of _exposing_ features rather than _implementing_ them, but it is not done yet (as of `0.2.0`).

What should come next:

- appending third-party blocks (verifying tokens with third-party blocks is already supported)
- saving and extracting snapshots
- sealing tokens

If you want to contribute to [biscuit-python][biscuit-python], adding these features would be a good way to get started.

Another thing on our radar is integration with web frameworks like [flask](https://flask.palletsprojects.com/en/2.3.x/) or [django](https://www.djangoproject.com/). If you're an experienced pythonista, we want to hear from you!

[biscuit-rust]: https://crates.io/crates/biscuit-auth
[biscuit-wasm]: https://npmjs.com/package/@biscuit-auth/biscuit-wasm
[biscuit-python]: https://pypi.org/project/biscuit-python

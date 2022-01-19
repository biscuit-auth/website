+++
title = "Biscuit 2.0 release"
description = "Introducing Biscuit 2.0"
date = 2022-01-16T09:19:42+00:00
updated = 2022-14-01T09:19:42+00:00
draft = true
template = "blog/page.html"

[taxonomies]
authors = ["Rustaceans"]

[extra]
lead = "Biscuit 2.0 announcement"
+++

We are delighted to announce the release of Biscuit at version 2.0! Biscuit is a specification
for a cryptographically verified authorization token supporting offline delegation, and a
language for authorization policies based on Datalog. It has been in development for 3 years
and is already deployed in production systems.

Biscuit was designed to address new challenges in building authorization in distributed systems:
- a query going through microservices must be verifiable decentrally without giving its full
authrization level to every node
- API authorization increasingly has to fit a user's authorization landscape (teams, roles,
delegation) while guaranteeing multitenant isolation

As an example, [Clever Cloud](https://www.clever-cloud.com)'s Pulsar service is accessible
with Biscuit tokens: each customer is provided a token with full access to their namespace,
and from there new tokens can be created that are limited to producing or subscribing to
specific topics, exactly according to application needs, without adding specific code on
the server's side.

To support those use cases, Biscuit specifies a token with public key signatures (like JWT)
and offline attenuation (like Macaroons): any service that knows the public key can verify
the token. And any token holder can derive a new token with more restrictions. For the
microservices use case, that means a node can take the token it received, and create a new one
with the least privilege before sending it to the next node.

To guarantee that authorization policies execute the same way everywhere, Biscuit provides
an authorization language based on Datalog, that all implementations must support.
This logic language comes with benefits about execution (guaranteed to terminate) and
serialization (small enough to be carried in the token) while keeping nearly as much
expressiveness as SQL.

You can test it right there, in your browser:

{% datalog() %}
// we receive a request to read "admin.doc"
// The request contains a token with the following content
user(1234);

// this restricts the kind of operation to "read"
check if operation("read");

// The authorizer loads facts representing the request
resource("admin.txt");
operation("read");

// The authorizer loads the user's rights
right(1234, "admin.txt", "read");
right(1234, "admin.txt", "write");

// Finally, the authorizer tests policies
// by looking for a set of facts matching them
allow if
  user($user_id),
  resource($res),
  operation($op),
  right($user_id, $res, $op);
{% end %}

While Biscuit has great ambitions for your systems, it can be integrated right
now without replacing the entire authorization stack: you can use it to carry
user ids and API keys, and benefit from attenuation on the client side.

And with this 2.0 release, we made it easier to integrate, simplified the
authorization language and improved performance.

The first big improvement of Biscuit 2.0 is the new cryptographic scheme. It has
evolved over the course of the project, from pairing based cryptography to
verifiable random functions in initial development, gamma signatures in 1.0,
and now a much simpler PKI system based on Ed25519 signatures. It keeps the main
property as previous designs: a new token can be created from an existing one
by adding a new block of data, and signatures will be valid.

That new scheme is simpler to write and audit, and can be implemented in almost
every language (in most cases, FFI to libsodium will be enough). It is also a lot
faster to sign and verify.

The second change is about Datalog execution. In a token, the first block contains
the initial rights as facts, created by the root of trust. In 1.0, to avoid confusion
with facts from the next blocks, they were tagged with the `#authority` symbol, and
facts provided by the authorizer from request data had the `#ambient` tag.

In 2.0, Datalog execution is better isolated, it makes sure that there will be no
interference from later blocks, without requiring `#authority` or `#ambient`.
This simplifies writing policies significantly.

We also removed entirely the Symbol type (marked with the `#`). Symbols were interned
strings, separated from normal strings. They were used to reduce the token's size: if
a symbol appeared multiple times, the token would only carry the string once, and refer
to it by a number. It also improved performance of Datalog execution, because symbols
could be matched by comparing numbers instead of string equality. It came with a
tradeoff: symbols did not support string operations like prefix matching.
Now all strings are interned, supporting all operations, so the symbols are not needed
anymore, and execution gets a performance boost.

Outline:
- short description of Biscuit: this might be the first time readers hear about it
  - why it was designed
  - features: datalog, attenuation
  - executable example
  - where does it fit in my tech stack?
- Biscuit 2.0
  - what happened since 1.0
  - why some changes were needed
  - what changed: crypto changes, datalog execution
- exciting new things
  - Haskell implementation
  - new wasm implementation
  - web components
- we need help
  - implementations that need to get to 2.0: Go, Java, C#, Swift
  - suggestions for new examples and docs
  - spec points that need to be decided
    - signatures exposed in datalog
    - 3rd party caveats
    - other signature algorithms (ecdsa)

+++
title = "Introduction"
description = "Biscuit is an authorization token that can be verified with public key cryptography, attenuated offline, using a Datalog based language for authorization policies"
date = 2021-05-01T08:00:00+00:00
updated = 2021-05-01T08:00:00+00:00
draft = false
weight = 10
sort_by = "weight"
template = "docs/page.html"

[extra]
#lead = "Biscuit is an authorization token that can be verified with public key cryptography, attenuated offline, using a Datalog based language for authorization policies."
toc = true
top = false
+++

<img src="/img/token_disambiguation.jpg" style="width: 100%" />


Biscuit is a set of building blocks for your authorization layer. By making a coherent experience from the authorization token up to the tools to write policies, it spares you the time spent binding together token scopes, authorization servers, and making sure authorization policies execute correctly in every service. You only need to focus on writing, debugging and deploying your rules.

## Biscuit is a bearer token

One of those building blocks is an authorization token that is signed with public key cryptography (like JWT), so that any service knowing the public key can verify the token. But it does a lot more! It supports offline attenuation (like Macaroons): from a Biscuit token, you can create a new one with more restrictions, without communicating with the service that created the token.

With that, you could have a token carried along with a series of requests between microservices, with the token reducing its rights as it goes deeper in the system. Or you could get a token from, say, a git repository hosting service, and attenuate it to just the set of rights needed for usage in CI.
Offline attenuation unlocks powerful delegation patterns, without needing to support them directly in the origin service.

Here is what a biscuit looks like: the left-hand side shows you the encoded token, while the right-hand side shows its contents: the first block (called the _authority block_) gives us what the token grants access to, while the two other blocks restrict how the token can be used. Only the authority block can be created by the token emitter, while the other blocks can be freely added by intermediate parties (_offline attenuation_).

<bc-token-printer biscuit="En0KEwoEMTIzNBgDIgkKBwgKEgMYgAgSJAgAEiAs2CFWr5WyHHWEiMhTXxVNw4gP7PlADPaGfr_AQk9WohpA6LZTjFfFhcFQrMsp2O7bOI9BOzP-jIE5PGhha62HDfX4t5FLQivX5rUhH5iTv2c-rd0kDSazrww4cD1UCeytDSIiCiCfMgpVPOuqq371l1wHVhCXoIscKW-wrwiKN80vR_Rfzg==">
</bc-token-printer>

## Biscuit is a policy language

Authorization policies are written in a logic language derived from [Datalog](https://en.wikipedia.org/wiki/Datalog). Logic languages are well suited for authorization, because they can represent complex relations between elements (like roles, groups, hierarchies) concisely, and efficiently explore and combine multiple rules.
Biscuit's authorization rules can be provided by the authorizer's side, but also by the token: while it can carry data, it can also contain "checks", conditions that the request must fulfill to be accepted. This is the main mechanism for attenuation: take an existing token, add a check for the current date (expiration) or the operation (restrict to read only).

<div class="text-left">
{% datalog() %}
// we receive a request to read "admin.doc"
// The request contains a token with the following content
user("1234"); // the user is identified as "1234"
check if operation("read"); // the token is restricted to read-only operations

// The authorizer loads facts representing the request
resource("admin.txt");
operation("read");

// The authorizer loads the user's rights
right("1234", "admin.txt", "read");
right("1234", "admin.txt", "write");

// Finally, the authorizer tests policies
// by looking for a set of facts matching them
allow if
  user($user_id),
  resource($res),
  operation($op),
  right($user_id, $res, $op);

{% end %}
</div>

Those authorization policies can be hardcoded in your application or be dynamically generated based on context.

Biscuit also comes with a command line application to create, attenuate, inspect and authorize tokens, an online playground for Datalog policies, and web assembly components to make frontend tools around policies development.

To sum up, Biscuit provides tools to build a complete, cross platform authorization system:

- an authorization token, verified by public key cryptography, that supports offline attenuation
- a logic language based on Datalog to write authorization policies
- a server side library, available for multiple languages, to write authorizers in your applications
- a command line application to create, attenuate, inspect and authorize tokens
- WebAssembly components to create, attenuate, inspect and authorize tokens, as well as to write and debug authorization policies

# Go further

*Getting started:* Create and verify your first biscuit in a step-by-step guide. [Getting started](../my-first-biscuit/)

*Datalog reference:* Learn about the logic language who's powering biscuits [Datalog reference](../../reference/datalog/)

*Policies cookbook:* Have a look at different ways to use biscuits to implement your security policies [Policies cookbook](../policies/)

*Contributing:* Find out how to contribute to Biscuit. [Contributing →](../../contributing/how-to-contribute/)

*Get help on Biscuit:* [Help →](../../help/faq/)

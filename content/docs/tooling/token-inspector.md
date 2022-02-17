+++
title = "Token inspector"
description = "Inspect a biscuit token"
date = 2022-02-17T11:20:00+02:00
updated = 2022-02-17T11:20:00+02:00
draft = false
weight = 1
sort_by = "weight"
template = "docs/page.html"
+++

You can paste a token in the textarea to inspect its contents.
You can also run an authorizer on the token.

Everything happens client-side, the token is not sent anywhere.

<bc-token-printer showAuthorizer="true"></bc-token-printer>

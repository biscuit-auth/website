+++
title = "Common patterns"
description = "Commonly used techniques"
date = 2021-05-01T08:00:00+00:00
updated = 2021-05-01T08:00:00+00:00
draft = false
weight = 10
sort_by = "weight"
template = "docs/page.html"

[extra]
lead = "Commonly used techniques and authorization patterns"
toc = true
top = false
+++

## Expiration check

A token can carry an expiration date:

<bc-datalog-playground showBlocks="true">
  <code class="block">
check if time($date), $date <= 2022-03-30T20:00:00Z;
  </code>
  <code class="authorizer">
// the authorizer can provide a fact containing the current date
time(2022-03-30T19:00:00Z);
allow if true;
  </code>
</bc-datalog-playground>

Attenuation can add more expiration checks, and all of them will be tested:

<bc-datalog-playground showBlocks="true">
  <code class="block">
check if time($date), $date <= 2022-03-30T20:00:00Z;
  </code>
    <code class="block">
check if time($date), $date <= 2022-03-30T18:30:00Z;
  </code>
  <code class="authorizer">
// the authorizer can provide a fact containing the current date
time(2022-03-30T19:00:00Z);
allow if true;
  </code>
</bc-datalog-playground>
+++
title = "Datalog playground"
description = "Test datalog evaluation"
date = 2022-02-17T11:20:00+02:00
updated = 2022-02-17T11:20:00+02:00
draft = false
weight = 4
sort_by = "weight"
template = "docs/page.html"
+++

<bc-datalog-playground showBlocks="true">
  <code class="block">
    right("/file1", "read");
    right("/file2", "read");
    right("/file2", "write");
check if operation("read");
  </code>
  <code class="authorizer">
    operation("read");
    file("/file1");

    can_view($file) <- right($file, "read");
    allow if file($f), operation($op), right($f, $op);
  </code>
</bc-datalog-playground>


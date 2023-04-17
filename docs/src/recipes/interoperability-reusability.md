# Interoperability & Reusability

In small biscuit deployments (a couple of services, in a single
organization), you have full control on which rules and facts are
defined and have meaning. On bigger deployments (across multiple
organizations, or if you want to design a reusable library that can
be used by multiple services), you will need to be more careful
about avoiding name collisions.

While there are no well-defined patterns that have emerged yet,
a good practice is to prefix fact names with the organization name,
separated by a colon (`:`). So for instance:

<bc-datalog-editor>
<pre><code>
// can collide with other facts
user("1234");

// makes it clear that the user is tied to a specific organization
wayne_industries:user("1234");
</code></pre>
</bc-datalog-editor> 

## A few notes

Using namespaced fact names will make tokens a bit bigger for two reasons:

- well, they're longer;
- names like `user` that are part of the default symbol table are only represented by an index in the wire format.

The size increase will be mitigated by string interning (you only pay the extra
cost once).

Another thing to note is that _namespacing is not a security feature_. It prevents
accidental name collisions, but is not a proper way to separate facts based on
their origin. Third party blocks provide such a mechanism. Namespacing can be
used _in conjuction_, to make things easier to read and understand.

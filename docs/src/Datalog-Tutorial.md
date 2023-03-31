# Datalog Tutorial

Datalog is a declarative logic language that is a subset of Prolog.
A Datalog program contains "facts", which represent data, and
"rules", which can generate new facts from existing ones.

As an example, we could define the following facts, describing some
relationships:

```
parent("Alice", "Bob");
parent("Bob", "Charles");
parent("Charles", "Denise");
```

This means that Alice is Bob's parent, and so on.

This could be seen as a table in a relational database:

| parent |         |         |
| ------ | -       | -       |
|        | Alice   | Bob     |
|        | Bob     | Charles |
|        | Charles | Denise  |

We can then define rules to create new facts, like this one: (a rule is made of a "head" on the left of `<-` indicating the data that is generated, variables are introduced with the `$` sign)

```
grandparent($grandparent, $child) <- parent($grandparent, $parent),
  parent($parent, $child)
```

Applying this rule will look at combinations of the `parent` facts
as defined on the right side of the arrow (the "body" of the rule),
and try to match them to the variables (`$grandparent`, `$parent`, `$child`):
- `parent("Alice", "Bob"), parent("Bob", "Charles")` matches because we can replace `$grandparent` with `"Alice"`, `$parent` with `"Bob"`, `$child` with `"Charles"`
- `parent("Alice", "Bob"), parent("Charles", "Denise")` does not match because we would get different values for the `$parent` variable

For each matching combination of facts in the body, we will then
generate a fact, as defined on the left side of the arrow, the "head"
of the rule. For `parent("Alice", "Bob"), parent("Bob", "Charles")`,
we would generate `grandparent("Alice", "Charles")`. A fact can be
generated from multiple rules, but we will get only one instance of it.

Going through all the combinations, we will generate:

```
grandparent("Alice", "Charles");
grandparent("Bob", "Denise");
```

which can be seen as:

| grandparent |       |         |
| ------      | -     | -       |
|             | Alice | Charles |
|             | Bob   | Denise  |

A Fact can be created from multiple rules, and a rule can use facts
generated from previous applications. If we added the following rules:

```
ancestor($parent, $child) <- parent($parent, $child);
ancestor($parent, $descendant) <- parent($parent, $child),
  ancestor($child, $descendant);
```

It would generate the following facts from the first one:

```
ancestor("Alice", "Bob");
ancestor("Bob", "Charles");
ancestor("Charles", "Denise");
```

Then the second rule could apply as follows:

- `ancestor("Alice", "Charles") <- parent("Alice", "Bob"), ancestor("Bob", "Charles")`
- `ancestor("Bob", "Denise") <- parent("Bob", "Charles"), ancestor("Charles", "Denise")`

So we would have:

```
ancestor("Alice", "Bob");
ancestor("Bob", "Charles");
ancestor("Charles", "Denise");
ancestor("Alice", "Charles");
ancestor("Bob", "Denise");
```

Then we reapply the second rule:

- `ancestor("Alice", "Denise") <- parent("Alice", "Bob"), ancestor("Bob", "Denise")`

So in the end we would have:

```
ancestor("Alice", "Bob");
ancestor("Bob", "Charles");
ancestor("Charles", "Denise");
ancestor("Alice", "Charles");
ancestor("Bob", "Denise");
ancestor("Alice", "Denise");
```

Interactions with a Datalog program are done through queries: **a query contains
a rule** that we apply over the system, and **it returns the generated facts**.

## Executable playground

<div class="text-left">
{% datalog() %}
parent("Alice", "Bob");
parent("Bob", "Charles");
parent("Charles", "Denise");
grandparent($grandparent, $child) <-
  parent($grandparent, $parent),
  parent($parent, $child);
ancestor($parent, $child) <- parent($parent, $child);
ancestor($parent, $descendant) <-
  parent($parent, $child),
  ancestor($child, $descendant);
{% end %}
</div>

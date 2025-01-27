# Datalog

## Facts

In Datalog, data is represented by facts. They come in the format `fact_name(42, "string")`. The fact has a name that indicates the "type", and between parenthesis, a tuple of data. Facts could be seen as rows in a relational database.

All of the tasks around Datalog consists in selecting data from facts, and generating new ones.

### Namespacing

Fact names can contain colons (`:`). While they don’t mean anything particular to the datalog engine, they are meant as a namespace
separator: when your rules start to grow, or if you want to provide reusable rules that don’t clash with others, you can _namespace_
your datalog facts and rules:

<bc-datalog-editor>
<pre><code>
service_a:fact_name(42);
</code></pre>
</bc-datalog-editor> 

## Data types

A fact contains data of the following types:

* integer: 64 bits signed integers `12`
* string: UTF-8 strings `"string"`
* byte array: represented as hexadecimal in the text format `hex:01A2`
* date: in [RFC 3339 format](https://datatracker.ietf.org/doc/html/rfc3339): `1985-04-12T23:20:50.52Z`
* boolean: `true` or `false`
* set: a deduplicated list of values of any type (except set)`[ "a", "b", "c"]`

## Rules

Rules are used to generate new facts from existing ones. They specify a pattern to select facts and extract data from them.
When we execute the rule `right($resource, "write") <- user($user_id), owner($user_id, $resource)`, we will look at all the `user` facts, and for each one, look at the `owner` facts with a matching `$user_id` value, select the second element from the fact with the `$resource` variable, and create a new fact from it.

<bc-datalog-playground>
<pre><code class="authorizer">
right($resource, "write") <- user($user_id), owner($user_id, $resource);
user(1);
owner(1, "file1.txt");
owner(1, "file2.txt");
owner(2, "file3.txt");
allow if true;
</code></pre>
</bc-datalog-playground> 

A rule contains data of the following types:

* variable: `$variable`
* integer: 64 bits signed integers `12`
* string: UTF-8 strings `"string"`
* byte array: represented as hexadecimal in the text format `hex:01A2`
* date: in [RFC 3339 format](https://datatracker.ietf.org/doc/html/rfc3339): `1985-04-12T23:20:50.52Z`
* boolean: `true` or `false`
* set: a deduplicated list of values of any type (except set or variable)`[ "a", "b", "c"]`

### Expressions

Rules filter data by matching between facts, but also by putting constraints on the variables. We could add a path prefix constraint to our previous rule like this: `right($resource, "write") <- user($user_id), owner($user_id, $resource), $resource.starts_with("/folder1/")`

Expressions return a boolean. If all the expressions in a rule return true for a selection of facts, it will produce a new fact.

Expressions can use the following operations:

#### Unary operations

Here are the currently defined unary operations:

* parens: returns its argument without modification : `1 + ( 2 + 3 )`
* negate: boolean negation `!( 1 < 2 )`
* length: defined on strings, byte arrays and sets, returns an int `"hello".length()`

#### Binary operations

Here are the currently defined binary operations:

* less than, defined on integers and dates, returns a boolean `<`
* greater than, defined on integers and dates, returns a boolean `>`
* less or equal, defined on integers and dates, returns a boolean `<=`
* greater or equal, defined on integers and dates, returns a boolean `>=`
* equal, defined on integers, strings, byte arrays, dates, set, returns a boolean `==`
* contains takes either:
  * a set and another value as argument, returns a boolean. Between two sets, indicates if the first set is a superset of the second one `$set.contains(1)`
  * two strings, and returns a boolean, indicating if the second string is a substring of the first `"a long string".contains("long")`
* prefix, defined on strings, returns a boolean `$str.starts_with("hello")`
* suffix, defined on strings, returns a boolean `$str.ends_with("world")`
* regex, defined on strings, returns a boolean `$str.matches("ab?c")`
* add, defined:
  * on integers, returns an integer `+`
  * on strings, concatenates two strings `"a long" + " string"`
* sub, defined on integers, returns an integer `-`
* mul, defined on integers, returns an integer `*`
* div, defined on integers, returns an integer `/`
* and, defined on booleans, returns a boolean `&&`
* or, defined on booleans, returns a boolean `||`
* intersection, defined on sets, return a set that is the intersection of both arguments `$set.intersection([1, 2])`
* union, defined on sets, return a set that is the union of both arguments `$set.union([1, 2])`

### Checks and allow/deny policies

Datalog authorization is enforced by checks and allow/deny policies. All the checks will be evaluated, and if one of them does not validate, the request will be rejected. Policies are evaluated one by one, in the order specified by the authorizer, stopping at the first that triggers. If it was a deny policy, the request will be rejected. If it was an allow policy, and all checks passed, the request will be accepted.
If no policy matched, the request is rejected.

They have a format similar to rules:

<bc-datalog-playground>
<pre><code class="authorizer">
user("admin");
right("file1.txt", "read");
// check
check if right("file1.txt", "read");

// allow policy
allow if user("admin");

// deny policy
deny if true;
</code></pre>
</bc-datalog-playground> 

## Block scoping

Offline attenuation means that the token holder can freely add extra blocks to a token. The datalog engine is designed to ensure that
adding a block can only restrict what a token can do, and never extend it.

The main purpose of an attenuation block is to add checks that depend on facts defined by the authorizer.

To achieve that, facts are scoped; to each fact is associated its *origin*: the block that defined the check, or for facts generated by rules, the block of the rule, along with the block of all the facts matched by the rule body.

By default (ie. when not using `trusting` annotations), a rule, check or policy only trusts (considers) facts defined:

- in the authority block;
- in the authorizer;
- in the same block (for rules defined in attenuation blocks).
![datalog block scoping](/images/block-scoping.svg)

This model guarantees that adding a block can only restrict what a token can do: by default, the only effect of adding a block to a token is to add new checks.

<bc-datalog-playground showBlocks="true">
<pre><code class="block">
// the token emitter grants read access to file1
right("file1", "read");
// the authority block trusts facts from itself and the authorizer
check if action("read");
</code></pre>
<pre><code class="block">
right("file2", "read");
// blocks trust facts from the authority block and the authorizer
check if action("read");
// blocks trust their own facts
check if right("file2", "read");
</code></pre>
<pre><code class="authorizer">
resource("file1");
action("read");
// the authorizer does not trust facts from additional blocks
check if right("file2", "read");
// the authorizer trusts facts from the authority block
check if right("file1", "read");
allow if true;
</code></pre>
</bc-datalog-playground> 

### Scope annotations and third-party blocks

A rule body (the right-hand side of a `<-`) can specify a *scope annotation*, to change the default scoping behaviour. By default, only facts from the current block, the authorizer and the authority block are considered. Not adding a scope annotation is equivalent to adding `trusting authority` (the authorizer and current block are always trusted, even with a scope annotation).

Scope annotations are useful when working with *third-party blocks*: given a third-party block signed by a specific keypair, it is possible to use `trusting {public_key}` to trust facts coming from this block.

<bc-datalog-playground showBlocks="true">
<pre><code class="block">
// the token emitter grants read access to file1
right("file1", "read");
// the authority block trusts facts from itself and the authorizer
check if action("read");
</code></pre>
<pre><code class="block" privateKey="ed25519/4933a0b1dccbda376d018ff3be561e8eb0fd428062459ebd77352f9f67188257">
right("file2", "read");
// blocks trust facts from the authority block and the authorizer
check if action("read");
// blocks trust their own facts
check if right("file2", "read");
</code></pre>
<pre><code class="authorizer">
resource("file1");
action("read");
// by default the authorizer trusts facts from the authority block
check if right("file1", "read");
check if right("file1", "read") trusting authority; // same as without the annotation
// the authorizer trusts facts from blocks signed by specific keys, when asked
check if right("file2", "read") trusting ed25519/b2d798062e2ac0d383ed8f75980959bcc0cc2fec8ebe0c77fbe8697dcc552946;
// the authorizer doesn't trust facts from the authority block, when not asked:
// there is a scope annotation, but it does not mention authority
check if right("file1", "read") trusting ed25519/b2d798062e2ac0d383ed8f75980959bcc0cc2fec8ebe0c77fbe8697dcc552946;
// the authorizer does not trust facts from additional blocks by default
check if right("file2", "read");
allow if true;
</code></pre>
</bc-datalog-playground> 


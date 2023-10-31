# Authorization performance

Authorization is likely part of your request handling hot path. As such, it is natural to try and make it as fast as possible. Signatures verification makes up for significant share of the time spent in the authorization process.

## Authorization process breakdown

The authorization process can be broken down in 4 parts:

- parsing;
- signature verification;
- datalog generation;
- datalog evaluation.

Parsing is typically one of the fastest steps; it depends only on the token size. Signature verification is where most of the time is spent; it depends mostly on the number of blocks (and their size). Datalog generation and datalog evaluation happen in tandem. That's the part where you have the most leverage. Datalog generation purely depends on how your application is designed. In many cases it can be done statically and thus have a negligible contribution to the overall runtime. Datalog evaluation depends on the actual datalog code that is evaluated.

## The first rule of performance optimization

> Don't do it

Benchmarks done with biscuit-rust show that the whole process (parsing, signatures verification and datalog generation and evaluation) usually clocks in at around one millisecond. In a lot of cases, that will not be a bottleneck and thus not where you should work on performance optimization.

## Measure

When it comes to performance optimization, the first step is always to measure things. First to determine if optimization is even needed, then to quantify progress.
This part entirely depends on your tech stack. You can start with coarse-grained traces telling you how long the whole authorization process takes, and then only dig down if optimization is needed.

Then, there are two steps in the authorization process that you can analyze: datalog generation, and datalog evaluation. 

The first step, datalog generation, is not likely to be the bottleneck in simple cases, with static authorization rules. However, if your datalog generation involves database queries and complex generation logic, then you have optimization opportunities.  
The second step is datalog evaluation. There might be a balance between those two steps (i.e. making the datalog generation process more complex in order to simplify evaluation), so optimizations should always be considered over the whole authorization process.

## Datalog performance contributors

As stated above, there are a lot of external factors that contribute to the final time and resource costs of the authorization process.

Other things being equal, some elements in datalog code tend to have a disproportionate effect on performance. This section lists the most common ones, in order to help you find the source of slowdowns.

With biscuit-rust, you can see how much time was spent evaluating datalog in an authorizer with `Authorizer.execution_time()`. This does not replace performance measurements, but can give you a simple way to compare datalog snippets. Authorizer snapshots carry this information and can be inspected with biscuit-cli through `biscuit inspect-snapshot` or with the web inspector.

### Number of rules

The number of rules is a direct contributor to evaluation performance. The datalog engine tries to match every rule with every fact to produce new facts, and then tries again with new facts until no new facts are produced.

- authorization contexts with a lot of rules will take more time to compute
- rules generating facts matched by other rule will require more iterations before convergence

### Expression evaluation

> This part is implementation-dependent, advice applies primarily to the rust implementation.

Rules can contain expressions, that are evaluated after facts are matched. The biscuit specification describes an evaluation strategy based on a stack machine, which aims at providing a fast evaluation.

#### Expensive operations

Operations on booleans, integers and dates are really simple operations and thus quite fast. Same for string equality, thanks to string interning (comparing two strings for equality is turned into an equality test on integers). Other string operations like prefix / suffix / substring tests are a bit more costly. Regex matching tends to be the worst offender, especially when there are a lot of different regexes. Regex compilation is memoized, so the cost can be amortized when one regex is used to match against several strings. However, if several regexes are matched against a single string, then the regex compilation costs will not be amortized.

#### Splitting expressions

Expressions are tried in order. If an expression evaluates to false (or fails to evaluate), other expressions are not evaluated. Splitting simple conditions and placing them first allows rules to fail fast by only evaluating complex operations when needed.

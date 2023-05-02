# Role based access control


Role-based access control is a common authorization model where a set of permissions is assigned to a role, and a user or program can have one or more roles.
This makes permissions more manageable than giving them to users directly: a role can be designed for a set of tasks, and can be given or taken back from the user depending on their duties, in one operation, instead of reviewing the user's entire set of rights. Changing the permissions of a role can also be done without going through all the users.

## Example

Let us imagine a space-faring package delivery company. Each member of the company has specific duties, represented by roles, that can perform specific actions.

<bc-datalog-editor>
<pre><code>
// let's define roles and associated permissions for a package delivery company
role("admin", ["billing:read", "billing:write", "address:read", "address:write"] );
// accountants can check the billing info and the address for invoicing
role("accounting", ["billing:read", "billing:write", "address:read"]);
// support people can update delivery info
role("support", ["address:read", "address:write"]);
// the pilot can drive and learn the delivery address
role("pilot", ["spaceship:drive", "address:read"]);
// delivery people can learn the address and handle the package
role("delivery", ["address:read", "package:load", "package:unload", "package:deliver"]);

// associate users to roles
// this would represent a database table holding both user data and roles,
// but similar facts could be derived from a join table between User and Role tables
user_roles(0, "Professor Farnsworth", ["admin"]);
user_roles(1, "Hermes Conrad", ["accounting"]);
user_roles(2, "Amy Wong", ["support"]);
user_roles(3, "Leela", ["pilot", "delivery"]);
user_roles(4, "Fry", ["delivery"]);
</code></pre>
</bc-datalog-editor> 

We want to check if an operation is authorized, depending on the user requesting it. Typically, the user id would be carried in a fact like`user(0)`, in the first block of a Biscuit token. Each employee gets issued their own token.

From that user id, we would look up in the database the user's roles, and for each role the authorized operations, and load that as facts. We can then check that we have the rights to perform the operation:

<bc-datalog-playground>
<pre><code class="authorizer">
role("admin", ["billing:read", "billing:write", "address:read", "address:write"] );
role("accounting", ["billing:read", "billing:write", "address:read"]);
role("support", ["address:read", "address:write"]);
role("pilot", ["spaceship:drive", "address:read"]);
role("delivery", ["address:read", "package:load", "package:unload", "package:deliver"]);

user_roles(0, "Professor Farnsworth", ["admin"]);
user_roles(1, "Hermes Conrad", ["accounting"]);
user_roles(2, "Amy Wong", ["support"]);
user_roles(3, "Leela", ["pilot", "delivery"]);
user_roles(4, "Fry", ["delivery"]);

// we got this from a cookie or Authorization header
user(1);
// we know from the request which kind of operation we want
operation("billing:write");

// we materialize the rights
right($id, $principal, $operation) <-
  user($id),
  operation($operation),
  user_roles($id, $principal, $roles),
  role($role, $permissions),
  $roles.contains($role),
  $permissions.contains($operation);

allow if
  operation($op),
  right($id, $principal, $op);

deny if true;
</code></pre>
</bc-datalog-playground> 

Why are we loading data from the database and checking the rights here, while we could do all of that as part of a SQL query? After all, Datalog is doing similar work, joining facts like we would join tables.

We actually need to use both: a SQL query to load only the data we need, because requesting all the users and roles on every request would quickly overload the database. And we load them in Datalog because we can encode more complex rules with multiple nested joins and more specific patterns. Example: we could get an attenuated token that only delegates rights from a particular role of the original user.

Another question: why are we creating the `right()` facts, instead of using the body of that rule directly in the allow policy?
Verifying inside the policy would work, but we would not get another benefit of Datalog here: we can use it to explore data. Try adding more `user()` facts and see which rights are generated. Try to add rules to answer specific questions.

**Example**: write a rule to get the list of employees that are authorized to deliver a package.

<details>
<summary>Answer</summary>
<bc-datalog-editor>
<pre><code>
can_deliver($name) <-
  role($role, $permissions),
  $permissions.contains("package:deliver"),
  user_roles($id, $name, $roles),
  $roles.contains($role);
</code></pre>
</bc-datalog-editor> 
</details>

## Resource specific roles

We only adressed authorization per operations, but often roles are also linked to a resource, like an organization in a SaaS application, a team or project in a project management software. Users can get different roles depending on the resource they access, and they can also get global roles.

We have high priority packages that need special handling, so not everybody can deliver them.
We will create different roles for normal and high priority packages. There are multiple ways this can be done, depending on your API and data model.
You could have a generic role or role assignment with a "resource type" field, like this:

<bc-datalog-editor>
<pre><code>
user_roles(3, "Leela", "high priority", ["pilot", "delivery"]);
user_roles(3, "Leela", "low priority", ["pilot", "delivery"]);
user_roles(4, "Fry", "low priority", ["delivery"]);
</code></pre>
</bc-datalog-editor> 

Or we could have roles defined per resource, and users are assigned those roles:

<bc-datalog-editor>
<pre><code>
role("low priority", "pilot", ["spaceship:drive", "address:read"]);
role("high priority", "pilot", ["spaceship:drive", "address:read"]);

user_roles(3, "Leela", "low priority", ["pilot", "delivery"]);
user_roles(3, "Leela", "high priority", ["pilot", "delivery"]);
</code></pre>
</bc-datalog-editor> 

Or even different types of roles:

<bc-datalog-editor>
<pre><code>
// using a numeric id as foreign key in users
role_high_priority("pilot", ["spaceship:drive", "address:read"]);
role_low_priority("pilot", ["spaceship:drive", "address:read"]);

// we need user_role or something else
user_high_priority(3, "Leela", ["pilot", "delivery"]);
user_low_priority(3, "Leela", ["pilot", "delivery"]);
</code></pre>
</bc-datalog-editor> 

Let's use the second version, and see how data is fetched from the database:

<bc-datalog-editor>
<pre><code>
// we got this from a cookie or Authorization header
user(3);
// we know from the request which kind of operation we want
operation("address:read");
// we know from the request we want to read the address of a high priority package
resource("high priority");

// user roles loaded from the database with the user id and resource
user_roles(3, "Leela", "high priority", ["pilot", "delivery"]);

// roles loaded from the ressource and the list from user_roles
role("high priority", "pilot", ["spaceship:drive", "address:read"]);
role("high priority", "delivery", ["address:read", "package:load", "package:unload", "package:deliver"]);

// we materialize the rights
right($id, $principal, $operation, $priority) <-
  user($id),
  operation($operation),
  resource($priority),
  user_roles($id, $principal, $priority, $roles),
  role($priority, $role, $permissions),
  $roles.contains($role),
  $permissions.contains($operation);
</code></pre>
</bc-datalog-editor> 

You can explore the full example here:

<bc-datalog-playground>
<pre><code class="authorizer">
role("low priority", "admin", ["billing:read", "billing:write", "address:read", "address:write"] );
role("low priority","accounting", ["billing:read", "billing:write", "address:read"]);
role("low priority","support", ["address:read", "address:write"]);
role("low priority", "pilot", ["spaceship:drive", "address:read"]);
role("low priority", "delivery", ["address:read", "package:load", "package:unload", "package:deliver"]);

role("high priority", "admin", ["billing:read", "billing:write", "address:read", "address:write"] );
role("high priority", "pilot", ["spaceship:drive", "address:read"]);
role("high priority", "delivery", ["address:read", "package:load", "package:unload", "package:deliver"]);

user_roles(0, "Professor Farnsworth", "low priority", ["admin"]);
user_roles(1, "Hermes Conrad", "low priority", ["accounting"]);
user_roles(2, "Amy Wong", "low priority", ["support"]);
user_roles(3, "Leela", "low priority", ["pilot", "delivery"]);
user_roles(4, "Fry", "low priority", ["delivery"]);

user_roles(0, "Professor Farnsworth", "high priority", ["admin"]);
user_roles(3, "Leela", "high priority", ["pilot", "delivery"]);


// we got this from a cookie or Authorization header
user(3);
// we know from the request which kind of operation we want
operation("address:read");
// we know from the request we want to read the address of a high priority package
resource("high priority");

// we materialize the rights
right($id, $principal, $operation, $priority) <-
  user($id),
  operation($operation),
  resource($priority),
  user_roles($id, $principal, $priority, $roles),
  role($priority, $role, $permissions),
  $roles.contains($role),
  $permissions.contains($operation);

allow if
  operation($op),
  resource($priority),
  right($id, $principal, $op, $priority);

deny if true;
</code></pre>
</bc-datalog-playground> 

## Attenuation

Roles work great when the user structure is well defined and does not change much, but they grow in complexity as we support more use cases, temporary access, transversal roles, interns, contractors, audits...

Attenuation in Biscuit provides a good escape hatch to avoid that complexity. As an example, let's assume that, for pressing reasons, Leela has to let Bender deliver the package (usually we do not trust Bender). Do we add a new role just for him? Does Leela need to contact headquarters to create it and issue a new token for Bender, in the middle of traveling?

Leela can instead take her own token, attenuate it to allow the delivery of high priority packages for a limited time. She can even seal the token to avoid other attenuations. We would end up with the following:

<bc-datalog-playground>
<pre><code class="authorizer">
// we got this from the first block of the token
user(3);

// the token is attenuated with a new block containing those checks
check if
  resource("high priority"),
  operation($op),
  role("high priority", "delivery", $permissions),
  $permissions.contains($op);
check if
  time($date),
  $date < 3000-01-31T12:00:00.00Z;

// data from the request
operation("address:read");
resource("high priority");
// provided by the authorizer
time(3000-01-31T11:00:00.00Z);

// user roles loaded from the user id in the first block
user_roles(3, "Leela", "high priority", ["pilot", "delivery"]);

// roles loaded from the ressource and the list from user_roles
role("high priority", "pilot", ["spaceship:drive", "address:read"]);
role("high priority", "delivery", ["address:read", "package:load", "package:unload", "package:deliver"]);

// we materialize the rights
right($id, $principal, $operation, $priority) <-
  user($id),
  operation($operation),
  resource($priority),
  user_roles($id, $principal, $priority, $roles),
  role($priority, $role, $permissions),
  $roles.contains($role),
  $permissions.contains($operation);

allow if
  operation($op),
  resource($priority),
  right($id, $principal, $op, $priority);

deny if true
</code></pre>
</bc-datalog-playground> 

Attenuating a token does not increase rights: if suddenly Leela loses the delivery role, the check of the attenuated token could succeed but authorization would fail both for Leela and Bender because the `right` fact would not be generated.
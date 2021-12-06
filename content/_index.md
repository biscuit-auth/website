+++
title = "Biscuit authorization"


# The homepage contents
[extra]
lead = '<b>Biscuit</b> is an authorization token with decentralized verification, offline attenuation and strong security policy enforcement based on a logic language'
url = "/docs/getting-started/introduction/"
url_button = "Get started"
repo_version = "Specification"
repo_license = "Open-source MIT License."
repo_url = "https://github.com/CleverCloud/biscuit"
token = "ErEBCkcKBWZpbGUxCgRyZWFkCgVmaWxlMgoFd3JpdGUYAiIMCgoIBBICGAcSAhgIIgwKCggEEgIYCRICGAgiDAoKCAQSAhgHEgIYChIkCAASIPDO-114IUTIGGx9OmnKx8s9VlfSUo0ZUGp30u6V2-fzGkCjGcwLyNuqXmP5GOIefbBvqAqWyIrLQ0gP2wOCpzfK3tebojcnvKcJYIdhe6tmJQUzns0NkZuzF5PmiSLdNsINGpwBCjIKBmNoZWNrMRgCMiYKJAoGCAsSAggCEgYIAhICCAISBggDEgIYCBIKCAQSAggCEgIYCBIkCAASIEj_cN0LNVf1luHuoGBc7a5u-nsABIHnHe11KcnSsr9pGkC2n6PB3wYlWrt_aIcsfpfzervjxwDj510e1RWrO0RLy8ZJJf8SAau-QATYn2j6PU8XcZi8NJD1Z8hg6-V_L-8MGogBCh4KBmNoZWNrMhgCMhIKEAoGCAwSAhgHEgYIAhICGAcSJAgAEiD2K6xN4msa4tYaSsxmeN_JveHBDoBHPHNTgR9oK5rC1RpAGpALWu-VhFdEopFCsbSW0uFlAKsyMvNtUKwLWFb5fq1ngdeKNcrZnUASc7MzX60Wv20DclchDuv6K7QixcMdByIiCiDp6ahTKwyXJbyHCFnHtAGRvN9j1I2TQr0iSYVJ7jodug=="

[[extra.list]]
title = "Decentralized verification"
content = 'Biscuit tokens are signed with public key cryptography: any application knowing the public key can verify the token'

[[extra.list]]
title = "Offline attenuation"
content = 'If you hold a valid token, you can generate a new one with less rights, like restricting write access or adding an expiration date'

[[extra.list]]
title = "Datalog policies"
content = 'Authorization policies are witten in a logic language. They can be provided by the application, or transported by the token (attenuation)'

# use cases

[[extra.list]]
title = "Capabilities or Access control lists"
content = 'Biscuit is naturally suited for capabilities based authorization, by carrying a token customized for the request. But you can also provide verification side ACLs as Datalog'

[[extra.list]]
title = "Revocation"
content = 'All tokens come with unique revocation identifiers, that can be used to reject that token and all the tokens attenuated from it'

[[extra.list]]
title = "Portable"
content = 'Biscuit is implemented in Rust, Haskell, Go, Java, WebAssembly, C... All you need for a new implementation is a Protobuf generator and Ed25519 signing. The specification comes with a list of predefined test cases'

+++

<h2>See it live</h2>
<p>Test authorization policies in Datalog:</p>
<div class="text-left">
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
</div>

+++
title = "Biscuit authorization"


# The homepage contents
[extra]
lead = '<b>Biscuit</b> is an authorization token with decentralized verification, offline attenuation and strong security policy enforcement based on a logic language'
url = "/docs/getting-started/introduction/index.html"
url_button = "Get started"
repo_version = "Specification"
repo_license = "Open-source MIT License."
repo_url = "https://github.com/biscuit-auth/biscuit"
token = "En0KEwoEMTIzNBgDIgkKBwgKEgMYgAgSJAgAEiAs2CFWr5WyHHWEiMhTXxVNw4gP7PlADPaGfr_AQk9WohpA6LZTjFfFhcFQrMsp2O7bOI9BOzP-jIE5PGhha62HDfX4t5FLQivX5rUhH5iTv2c-rd0kDSazrww4cD1UCeytDSIiCiCfMgpVPOuqq371l1wHVhCXoIscKW-wrwiKN80vR_Rfzg=="

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
resource("admin.doc");
operation("read");

// The authorizer loads the user's rights
right(1234, "admin.doc", "read");
right(1234, "admin.doc", "write");

// Finally, the authorizer tests policies
// by looking for a set of facts matching them
allow if
  user($user_id),
  resource($res),
  operation($op),
  right($user_id, $res, $op);

{% end %}
</div>

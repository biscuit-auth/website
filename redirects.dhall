let concatMap =
      https://prelude.dhall-lang.org/List/concatMap
        sha256:3b2167061d11fda1e4f6de0522cbe83e0d5ac4ef5ddf6bb0b2064470c5d3fb64

let Entry = { from : Text, to : Text, status : Natural, force : Bool }

let Conf = { oldPrefix : Text, newPrefix : Text }

let Mapping = { old : Text, new : Text }

let mkEntry =
      \(c : Conf) ->
      \(e : Mapping) ->
        [ { from = "/docs/${c.oldPrefix}/${e.old}/"
          , to = "https://doc.biscuitsec.org/${c.newPrefix}/${e.new}.html"
          , status = 301
          , force = True
          }
        , { from = "docs/${c.oldPrefix}/${e.old}/index.html"
          , to = "https://doc.biscuitsec.org/${c.newPrefix}/${e.new}.html"
          , status = 301
          , force = True
          }
        ]

let mkSectionEntry =
      \(e : Mapping) ->
        [ { from = "/docs/${e.old}"
          , to = "https://doc.biscuitsec.org/${e.new}.html"
          , status = 301
          , force = True
          }
        , { from = "docs/${e.old}/index.html"
          , to = "https://doc.biscuitsec.org/${e.new}.html"
          , status = 301
          , force = True
          }
        ]

let gettingStarted =
      concatMap
        Mapping
        Entry
        ( mkEntry
            { oldPrefix = "getting-started", newPrefix = "getting-started" }
        )
        [ { old = "introduction", new = "introduction" }
        , { old = "token", new = "introduction" }
        , { old = "my-first-biscuit", new = "my-first-biscuit" }
        , { old = "policies", new = "authorization-policies" }
        , { old = "datalog", new = "authorization-policies" }
        ]

let usage =
      concatMap
        Mapping
        Entry
        (mkEntry { oldPrefix = "Usage", newPrefix = "usage" })
        [ { old = "c", new = "c" }
        , { old = "go", new = "go" }
        , { old = "node", new = "nodejs" }
        , { old = "cli", new = "command-line" }
        , { old = "haskell", new = "haskell" }
        , { old = "java", new = "java" }
        , { old = "rust", new = "rust" }
        ]

let recipes =
      concatMap
        Mapping
        Entry
        (mkEntry { oldPrefix = "guides", newPrefix = "recipes" })
        [ { old = "common-patterns", new = "common-patterns" }
        , { old = "interop", new = "interoperability-reusability" }
        , { old = "rbac", new = "role-based-access-control" }
        ]

let reference =
      concatMap
        Text
        Entry
        ( \(t : Text) ->
            mkEntry
              { oldPrefix = "reference", newPrefix = "reference" }
              { old = t, new = t }
        )
        [ "cryptography", "datalog" ]

in  { redirects = gettingStarted # usage # recipes # reference }

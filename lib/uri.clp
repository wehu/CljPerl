(ns uri

  (. require URI)

  (defn path [u]
    (perl->clj (.URI path ^{:return "ref"} u)))

  (defn set-path [u p]
    (perl->clj (.URI path ^{:return "ref"} u p)))

  (defn query [u]
    (perl->clj (.URI query u)))

  (defn set-query [u q]
    (perl->clj (.URI query u q)))

  )

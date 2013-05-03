(ns uri

  (. require URI)

  (defn path [u]
    (perl->clj (.URI path u)))

  (defn set-path [u p]
    (perl->clj (.URI path u p)))

  (defn path-stem [u]
    (let [m (match "([^\\?]+)(\\?.*)?$" (path u))]
      (#:0 m)))

  (defn query [u]
    (perl->clj (.URI query u)))

  (defn set-query [u q]
    (perl->clj (.URI query u q)))

  )

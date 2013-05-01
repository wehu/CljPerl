(ns quoi

  (require file)
  (require anyevent-httpd)

  (def S {})

  (def routings {})

  (defn page [url file]
    (if (file#exists? file)
      (#:url routings (read file))
      (println (append file " does not exists"))))

  (defn start [opts]
    (anyevent-httpd#start-server
      opts
      routings))

  )

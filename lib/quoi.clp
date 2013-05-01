(ns quoi

  (require file)
  (require anyevent-httpd)

  (def S {})

  (def routings {})

  (defn page [url file]
    (#:url routings (fn []
      (if (eq (type file) "xml")
        file
        (read file)))))

  (defn start [opts]
    (let [s (anyevent-httpd#server opts)]
      (anyevent-httpd#reg-cb s
        {:request
          (fn [s req]
            (let [url (anyevent-httpd#url req)]
              (reduce (fn [k f]
                (let [m (match k url)]
                  (if (and (> (length m) 0)
                       f)
                    (begin
                      (anyevent-httpd#respond req
                        {"content" ["text/html"
                                    (clj->string ((#:k routings)))]})
                      (anyevent-httpd#stop-respond s)
                      false)
                    f)))
                true
                (keys routings))))})
      (anyevent-httpd#run s)))

  )

(ns quoi

  (require file)
  (require anyevent-httpd)

  (def S {})

  (def routings {})

  (defn page [url file]
    (#:url routings (fn [] (read file))))

  (defn start [opts]
    (let [s (anyevent-httpd#server opts)]
      (anyevent-httpd#reg-cb s
        {:request
          (fn [s req]
            (let [url (anyevent-httpd#url req)]
              (map (fn [k]
                (let [m (match k url)]
                  (if (> (length m) 0)
                    (begin
                      (anyevent-httpd#respond req
                        {"content" ["text/html"
                                    (clj->string ((#:k routings)))]})
                      (anyevent-httpd#stop-respond s)))))
                (keys routings))))})
      (anyevent-httpd#run s)))

  )

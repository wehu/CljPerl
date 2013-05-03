(ns quoi

  (require file)
  (require anyevent-httpd)
  (require uri)

  (def routings {})

  (defmacro file [n]
    `(fn [S] (read ~n)))

  (defn page [url file-fn-xml]
    (#:url routings (fn [req]
      (def S {:request req
              :url (anyevent-httpd#url req)
              :path (uri#path-stem (anyevent-httpd#url req))
              :method (anyevent-httpd#method req)
              :params (anyevent-httpd#params req)
              :headers (anyevent-httpd#headers req)
              :content (anyevent-httpd#content req)
              :client-host (anyevent-httpd#client-host req)
              :client-port (anyevent-httpd#client-port req)})
      (if (eq (type file-fn-xml) "xml")
        file-fn-xml
        (if (eq (type file-fn-xml) "function")
          (file-fn-xml S)
          (read file-fn-xml))))))

  (defn start [opts]
    (let [s (anyevent-httpd#server opts)]
      (anyevent-httpd#reg-cb s
        {:request
          (fn [s req]
            (let [url (anyevent-httpd#url req)
                  path (uri#path-stem url)]
              (reduce (fn [k f]
                (if f
                  (let [m (match "^/(image|javascript|stylesheet)s/(\\S+)" path)]
                    (if (> (length m) 0)
                      (let [t (#:0 m)
                            f (#:1 m)]
                        (begin
                          (anyevent-httpd#respond req
                            {"content" [(append "text/" t)
                                        (file#readlines (append t (append "s/" f)))]})
                          false))
                      (let [m (match k path)]
                        (if (> (length m) 0)
                          (begin
                            (anyevent-httpd#respond req
                              {"content" ["text/html"
                                          (clj->string ((#:k routings) req))]})
                            (anyevent-httpd#stop-respond s)
                            false)
                          f))))
                  f))
                true
                (keys routings))))})
      (anyevent-httpd#run s)))

  )

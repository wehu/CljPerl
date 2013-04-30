(ns anyevent-httpd

  (. require AnyEvent::HTTPD)

  (defn server [opts]
    (->AnyEvent::HTTPD new opts))

  (defn reg-cb [s opts]
    (.Object::Event reg_cb ^{:return "nil"} s opts))

  (defn respond [req o]
    (.AnyEvent::HTTPD::Request respond ^{:arguments ["scalar" "scalar"]} req o))

  (defn run [s]
    (.AnyEvent::HTTPD run s))

  (defn start-server [host-port opts]
    (let [s (server host-port)]
      (map (fn [k]
        (reg-cb s {k (fn [s req]
                       (respond req
                         {"content" ["text/html"
                                     (clj->string (#:k opts))]}))}))
        (keys opts))
      (run s)))

  )

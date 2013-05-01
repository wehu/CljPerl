(ns anyevent-httpd

  (. require AnyEvent::HTTPD)

  (defn server [opts]
    (->AnyEvent::HTTPD new opts))

  (defn reg-cb [s opts]
    (.Object::Event reg_cb ^{:return "nil"} s opts))

  (defn respond [req o]
    (.AnyEvent::HTTPD::Request respond ^{:arguments ["scalar" "scalar"]} req o))

  (defn stop-respond [s]
    (.AnyEvent::HTTPD stop_request s))

  (defn run [s]
    (.AnyEvent::HTTPD run s))

  (defn url [req]
    (.AnyEvent::HTTPD::Request url req))

  (defn method [req]
    (perl->clj (.AnyEvent::HTTPD::Request method req)))

  (defn params [req]
    (let [ps (perl->clj (.AnyEvent::HTTPD::Request params ^{:return "ref-array"} req))]
      (reduce
        (fn [p i]
          (#:p i (perl->clj (.AnyEvent::HTTPD::Request parm req p)))
          i)
        {}
        ps)))

  (defn headers [req]
    (perl->clj (.AnyEvent::HTTPD::Request headers ^{:return "ref"} req)))

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

(ns anyevent-httpd

  (. require AnyEvent::HTTPD)

  (defn server [opts]
    (->AnyEvent::HTTPD new opts))

  (defn reg-cb [s opts]
    (.Object::Event !reg_cb s opts))

  (defn respond [req o]
    (.AnyEvent::HTTPD::Request respond$$ req o))

  (defn run [s]
    (.AnyEvent::HTTPD run s))

  (defn start-server [host-port opts]
    (let [s (server host-port)]
      (reg-cb s opts)
      (run s)))

  )

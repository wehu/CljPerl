(ns anyevent-dbi

  (. require AnyEvent::DBI)

  (defn db [database user pass]
    (->AnyEvent::DBI new database user pass))

  (defn exec [database sql cb]
    (.AnyEvent::DBI exec database sql cb))

  )

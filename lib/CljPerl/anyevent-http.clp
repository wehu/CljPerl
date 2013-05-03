(ns anyevent-http

  (. require AnyEvent::HTTP)

  (defn get [url cb]
    (.AnyEvent::HTTP http_get url cb))

  )

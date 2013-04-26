(ns anyevent

  (. require AnyEvent)

  (defn condvar []
    (->AnyEvent condvar))

  (defn condvar-recv [cv]
    (.AnyEvent::CondVar::Base recv cv))

  (defn condvar-send [cv & args]
    (.AnyEvent::CondVar::Base send cv args))

  (defn timer [opts]
    (->AnyEvent timer opts))

  (defn cancel-timer [t]
    (set! t nil))

  )

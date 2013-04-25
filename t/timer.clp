(. require AnyEvent)

(def cv (->AnyEvent condvar))

(def count 0)

(def t (->AnyEvent timer
  {:after 1
   :interval 1
   :cb (fn [ & args]
         (println count)
         (set! count (+ count 1))
         (if (>= count 10)
           (set! t nil)))}))

(.AnyEvent::CondVar::Base recv cv)


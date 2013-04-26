(require anyevent)

(def cv (anyevent#condvar))

(def count 0)

(def t (anyevent#timer
  {:after 1
   :interval 1
   :cb (fn [ & args]
         (println count)
         (set! count (+ count 1))
         (if (>= count 10)
           (begin 
             (anyevent#condvar-send cv)
             (anyevent#cancel t))))}))

(anyevent#condvar-recv cv)


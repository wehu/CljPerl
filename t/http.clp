(require anyevent-http)
(require anyevent)

(def cv (anyevent#condvar)) 

(def hg (anyevent-http#get "http://www.google.com"
  (fn [data header]
    (println data)
    (println header)
    (anyevent#condvar-send cv)
    (anyevent#cancel hg))))

(anyevent#condvar-recv cv)

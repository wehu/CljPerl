(def a 'b)
((fn [b & c]
  (def a 'c)
  (println a)
  (println b)
  (println c))
 'a
)
(defmacro c [a & d]
  `(println ~a))

(c 'b)
(c 'e)

(defmacro defn [name args & body]
  `(def ~name
     (fn ~args ~@body)))

(defn foo [a]
  (println a))

(foo "asjfl\tdjsdfd!") ;yyy

(foo 1233434)

(foo :abc)

(.CljPerl print "aaa\n")

(. print "bbb\n")

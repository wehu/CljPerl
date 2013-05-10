(def a 'b)
((fn [b & c]
  (def a 'c)
  (println a)
  (println b)
  (println c))
 'a 'c 'e
)
(defmacro c [a & d]
  `(println ~a))

(c 'b)
(c '(a b c) 'd)

(println (car '(a b c)))
(println (cdr '(a b c)))
(println (cons 'b '(a b c)))

(println (list 'b '(a b c)))

(println ['a 'b 'c])
(println {:abc 'b})

(println (length (list 'b '(a b c))))

(println (length ['a 'b 'c]))
(println (length {:abc 'b}))

(println (length "abcde"))

(println (! false))

(println (eq "a" "b"))
(println (eq "a\n" "a\n"))

(defmacro defn [name args & body]
  `(def ~name
     (fn ~args ~@body)))

(defn foo [a]
  (println a))

(if true
  (println 'true)
; ljfdljd
  (println 'false)) 

(if false
  (println 'true)
  (println 'false))

(def i 0)
(def cond true)
(println i)
(println (+ i 1))
(while cond
  (if (> i 3) (set! cond false))
  (set! i (+ i 1))
  (println i))

(foo "asjfl\tdjsdfd!") ;yyy

(foo 1233434)

(foo :abc)

(println (equal "a" 1))
(println (equal "a" "a"))
(println (equal () ()))
(println (equal :a :b))
(println (equal :a :a))
(println (equal 'a 'b))
(println (equal 'a 'a))


(def m {:abc 100})
(println (#::abc m))
(#::abc m 101)
(println (#::abc m))

(set! m [102 103])
(println (#:0 m))
(#:1 m 101)
(println (#:1 m))


(.CljPerl print "aaa\n")

(println (. print "bbb\n"))

(println (eval "(+ 1 2)"))

(def ^{:a 'b} m 1)
(println (meta m))
(println (type m))
(#::a (meta m) 'c)
(println (meta m))

(require "../lib/CljPerl/core.clp")

(defmulti mf type)
(println (meta mf))
(defmethod mf "string" [a] (println "string"))
(defmethod mf "keyword" [a] (println "keyword"))
(println (meta mf))
(mf "a")
(mf :b)

(apply println '(:a))

(defn bar [afn arg]
  (afn arg))

(bar println :b)

(def bar println)
(bar :bar)

(println (reduce (fn [a i]
  (cons (+ a 1) i))
  '()
  '(1 2 3)))

(set! i 0)
((fn [a] (set! a i)) 1)
(println i)

(meta i ^{:a 1})
(println (meta i))

(println (append "abc" "def"))
(println (append '(a b c) '(def)))
(println (append [:a :b :c] [:a :b :c]))
(println (append {:a :b} {:c :d}))

(println (keys {"a" :b :c :d}))
(println (#:"a" {"a" :b}))

(println (map (fn [i]
   (+ i 1))
  `(1 2 3)))

(namespace-begin "aaa")
(def aaa 0)
(println aaa)
(namespace-end)
(println aaa#aaa)

(ns "foo"
  (def bar0 'bar0)
  (defn bar []
    bar0))
(ns "bar"
  (def bar0 'bar1)
  (println (foo#bar)))

(. openfile ">t.txt" (fn [f]
  (println "bbbb")
  (. puts f "aaa")))

(println (clj->string {:a 'b}))

(println (gen-name))

(println `:aa)

(println (syntax `aa))

(let [a 1]
  (let [a 2
        b a]
    (println a)
    (println b)))

(def sender (fn [ & args] (println args)))

(#!"sender" "bbb")

(println #[abc ^{:abc "bb"} #[ccd]])

(println (match "(\\w)" "abc"))

(println (and true true))
(println (or true false))
(println (and true false))
(println (or false false))

(println (xml-name #[html]))

(require "xml")

(println ($ "#aa" #[html "aaaa" #[a ^{:id "aa"} "a"]]
  (fn [xml]
    #[b "aaa"])))

(println ($ "[id=aa]" #[html "aaaa" #[a ^{:id "aa"} "a"]]
  (fn [xml]
    #[b "aaa"])))

(println (object-id "aaa"))

(println (gen-sym "sym"))


(defmacro test-gen-sym []
  (let [s (gen-sym)]
    `(let [~s "aa"]
       (println ~s))))

(test-gen-sym)

(
(fn []
(catch (throw aaa "bbb") (fn [e] (println e)
(println (exception-label e))
(println (exception-message e))))))

((fn []
 (catch
  ((fn []
     (throw aaa "bbb")))
  (fn [e]
    (println e)))))

(cond
  [true (println "a")]
  [else (println "b")])

(println (env "PATH"))

(def c0 (coroutine
  (println "a")
  (coro-sleep)
  (println (coro-current))
  (println (coro-main))
  (println "d")))

(println "b")
(coro-resume c0)
(println "c")
(println (coro-current))
(coro-resume c0)


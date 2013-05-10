(defmacro ns [name & body]
  `(begin
     (namespace-begin ~name)
     ~@body
     (namespace-end)))

(defmacro defn [name args & body]
  `(def ~name
     (fn ~args ~@body)))

(defmacro defmulti [name dispatch-fn]
  `(def ^{} ~name (fn [dispatch-val & args]
     (apply (#:(~dispatch-fn dispatch-val) (meta ~name)) (cons dispatch-val args)))))

(defmacro defmethod [name dispatch-val args & body]
  `(#:~dispatch-val (meta ~name)
     (fn ~args ~@body)))

; Do not use recursive function,
; since we do not support optimazation of tail call.
(defn reduce [afn init alist]
  (def res init)
  (def i 0)
  (def l (length alist))
  (while (< i l)
    (set! res (afn (#:i alist) res))
    (set! i (+ i 1)))
  res)

(defn map [afn alist]
  (reduce (fn [a i]
    (append i 
      (list (afn a))))
    ()
    alist))

(defn append-list [f & alist]
  (reduce
    (fn [a i]
      (append i a))
    (if (eq (type f) "string")
      ""
      (if (eq (type f) "list")
        ()
        []))
    (cons f alist)))

; append lib search path
(defn use-lib [path]
  (. use_lib path))

(defn gen-name []
  (perl->clj (. gen_name)))

; regexp
(defn match [regexp str]
  (perl->clj (. match regexp str)))

; cond
(defmacro cond [ & pairs]
  (reduce
    (fn [p i]
      (let [k (#:0 (syntax p))
            k (if (equal k `else) `true k)
            v (#:1 (syntax p))]
        `(if ~k
           ~v
           ~i)))
    `()
    (reverse pairs)))

; env
(defn env [n]
  (. get_env n))

; coroutine

(defmacro coroutine [ & body]
  `(coro (fn [] ~@body)))

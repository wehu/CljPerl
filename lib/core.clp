(defmacro defn [name args & body]
  `(def ~name
     (fn ~args ~@body)))

(defmacro defmulti [name dispatch-fn]
  `(def ^{} ~name (fn [dispatch-val & args]
     (apply ((~dispatch-fn dispatch-val) (meta ~name)) args))))

(defmacro defmethod [name dispatch-val args & body]
  `(~dispatch-val (meta ~name)
     (fn ~args ~@body)))

; do not use recursiv function,
; since we do not support optimazation of tail call.
(def reduce (fn [afn init alist]
  (def res init)
  (def i 0)
  (def l (length alist))
  (while (< i l)
    (set! res (afn (i alist) res))
    (set! i (+ i 1)))
  res))

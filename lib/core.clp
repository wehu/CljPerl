(defmacro defn [name args & body]
  `(def ~name
     (fn ~args ~@body)))

(defmacro defmulti [name dispatch-fn]
  `(def ^{} ~name (fn [dispatch-val & args]
     (apply ((~dispatch-fn dispatch-val) (meta ~name)) args))))

(defmacro defmethod [name dispatch-val args & body]
  `(~dispatch-val (meta ~name)
     (fn ~args ~@body)))


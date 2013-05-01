(require quoi)

(def alist (list "a" "b" "c"))

(map (fn [i]
  (quoi#page (append "/" (append i "$"))
    #[html #[body i]]))
  alist)

(quoi#page "/$"
  "t/index.clp")

(quoi#start {:port 9090})

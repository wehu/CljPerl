(require quoi)

(def alist (list "a" "b" "c"))

(map (fn [i]
  (quoi#page (append "/" (append i "$"))
    (fn [S]
      #[html #[body
        #[h1 i]
        #[p "url: " (#::path S)]
        #[p "method: " (#::method S)]
        #[p "params: " (clj->string (#::params S))]
        #[p "headers: " (clj->string (#::headers S))]]])))
  alist)

(quoi#page "/$"
  "t/index.clp")

(quoi#start {:port 9090})

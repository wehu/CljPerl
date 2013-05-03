(require quoi)
(require quoi/menu)

(def alist (list "a" "b" "c"))

(def menu (quoi#menu
  ["Home" "/home$" "home.clp"]
  ["About" "/about$" "about.clp"]))

(map (fn [i]
  (quoi#page (append "/" (append i "$"))
    (fn [S]
      #[html #[body
        #[h1 i]
        #[p "url: " (#::path S)]
        #[p "method: " (#::method S)]
        #[p "params: " (clj->string (#::params S))]
        #[p "headers: " (clj->string (#::headers S))]
        #[p "content: " (clj->string (#::content S))]
        #[p "client host: " (#::client-host S)]
        #[p "client port: " (#::client-port S)]
        #[a ^{:href "/"} "return"]]])))
  alist)

(quoi#page "/$"
  (fn [S]
    (read "t/index.clp")))

(quoi#start {:port 9090})

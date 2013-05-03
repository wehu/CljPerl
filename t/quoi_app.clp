(require quoi)
(require quoi/menu)
(require quoi/default_template)

(def alist (list "a" "b" "c"))

(def title "Quoi")

(def menu (quoi#menu
  ["Home" "home" (quoi#default-template title (quoi#file "t/index.clp"))]
  ["About" "about" (quoi#default-template title (quoi#file "t/about.clp"))]))

(map (fn [i]
  (quoi#page (append "/" (append i "$"))
    (quoi#default-template title
    (fn [S]
      #[html #[body
        menu
        #[h1 i]
        #[p "url: " (#::path S)]
        #[p "method: " (#::method S)]
        #[p "params: " (clj->string (#::params S))]
        #[p "headers: " (clj->string (#::headers S))]
        #[p "content: " (clj->string (#::content S))]
        #[p "client host: " (#::client-host S)]
        #[p "client port: " (#::client-port S)]
        #[a ^{:href "/"} "return"]]]))))
  alist)

(quoi#page "/$"
  (quoi#default-template title (quoi#file "t/index.clp")))

(quoi#start {:port 9090})

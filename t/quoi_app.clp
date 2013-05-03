(require quoi)
(require quoi/menu)
(require quoi/table)
(require quoi/default_template)

(def alist (list "a" "b" "c"))

(def title "Quoi")

(defn req-info [S]
  #[span
   #[p "Http Request Information"] 
  (quoi#sortable-table
    ["name" "value"] 
    ["path: " (#::path S)]
    ["method: " (#::method S)]
    ["params: " (clj->string (#::params S))]
    ["headers: " (clj->string (#::headers S))]
    ["content: " (clj->string (#::content S))]
    ["client host: " (#::client-host S)]
    ["client port: " (#::client-port S)])])

(def menu (quoi#superfish-menu
  ["Home" "home" (quoi#default-template title (quoi#file "t/index.clp"))]
  ["About" "about" (quoi#default-template title (quoi#file "t/about.clp"))]))

(map (fn [i]
  (quoi#page (append "/" (append i "$"))
    (quoi#default-template title
    (fn [S]
      #[span
        menu
        #[h1 i]
        (req-info S)
        ]))))
  alist)

(quoi#page "/$"
  (quoi#default-template title (quoi#file "t/index.clp")))

(quoi#start {:port 9090})

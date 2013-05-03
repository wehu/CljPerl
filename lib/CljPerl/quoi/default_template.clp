(ns quoi

  (defmacro default-template [title xml]
    `(fn [S]
      #[html
      ^{:xmlns "http://www.w3.org/1999/xhtml"}
      #[head
         #[meta ^{:http-equiv "content-type" :content "text/html; charset=UTF-8"}]
         #[meta ^{:name "description" :content ""}]
         #[meta ^{:name "keywords" :content ""}]
         #[title ~title]
         #[script ^{:id "jquery"
                    :src "/javascripts/jquery-1.9.1.min.js"
                    :type "text/javascript"}]
         #[link ^{:href "/stylesheets/markdown.css"
                  :rel "stylesheet"}]
         #[link ^{:href "/stylesheets/superfish.css"
                  :media "screen"
                  :rel "stylesheet"}]
         #[link ^{:href "/stylesheets/superfish-vertical.css"
                  :rel "stylesheet"}]
         #[link ^{:href "/stylesheets/superfish-navbar.css"
                  :rel "stylesheet"}]
         #[script ^{:src "/javascripts/hoverIntent.js"
                    :type "text/javascript"}]
         #[script ^{:src "/javascripts/superfish.js"
                    :type "text/javascript"}]
         #[link ^{:href "/stylesheets/themes/blue/style.css"
                  :rel "stylesheet"}]
         #[script ^{:src "/javascripts/jquery.tablesorter.min.js"
                    :type "text/javascript"}]]
      #[body
         #[h1 ^{:style "text-align: left"} title]
         #[hr]
         (let [x ~xml
               t (type x)]
           (if (eq t "xml")
             xml
             (if (eq t "function")
               (x S)
               (read x))))
         #[br]
         #[hr]
         #[p ^{:style "text-align:center"} "Copyright@wehu"]]]))

  )

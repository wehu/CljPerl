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
                    :src "http://ajax.googleapis.com/ajax/libs/jquery/1/jquery.min.js"
                    :type "text/javascript"}]
         #[link ^{:href "http://kevinburke.bitbucket.org/markdowncss/markdown.css"
                  :rel "stylesheet"}]
         #[link ^{:href "https://raw.github.com/joeldbirch/superfish/master/css/superfish.css"
                  :media "screen"
                  :rel "stylesheet"}]
         #[link ^{:href "https://raw.github.com/joeldbirch/superfish/master/css/superfish-vertical.css"
                  :rel "stylesheet"}]
         #[link ^{:href "https://raw.github.com/joeldbirch/superfish/master/css/superfish-navbar.css"
                  :rel "stylesheet"}]
         #[script ^{:src "https://raw.github.com/briancherne/jquery-hoverIntent/master/jquery.hoverIntent.js"
                    :type "text/javascript"}]
         #[script ^{:src "https://raw.github.com/joeldbirch/superfish/master/js/superfish.js"
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
               (read x))))]]))

  )

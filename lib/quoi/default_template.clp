(ns quoi

  (defmacro default-template [title xml]
    `(fn [S]
      #[html
      ^{:xmlns "http://www.w3.org/1999/xhtml"}
      #[head
         #[meta ^{:http-equiv "content-type" :content "text/html; charset=UTF-8"}]
         #[meta ^{:name "description" :content ""}]
         #[meta ^{:name "keywords" :content ""}]
         #[title ~title]]
         #[script ^{:id "jquery"
                    :src "http://code.jquery.com/jquery-1.9.1.min.js"
                    :type "/text/javascript"}]
         #[link ^{:href "http://kevinburke.bitbucket.org/markdowncss/markdown.css"
                  :rel "stylesheet"}]
      #[body
         (let [x ~xml
               t (type x)]
           (if (eq t "xml")
             xml
             (if (eq t "function")
               (x S)
               (read x))))]]))

  )

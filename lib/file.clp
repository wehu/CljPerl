(ns file
  ; file
  (defn open [file cb]
    (. open file cb))

  (defn >> [fh str]
    (. puts fh str))

  (defn << [fh]
    (. readline fh))

  (defn exists? [f]
    (let [r (perl->clj (. file_exists f))]
      (if (equal r "1")
        true
        false)))

  )

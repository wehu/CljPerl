(ns file
  ; file
  (defn open [file cb]
    (. open file cb))

  (defn >> [fh str]
    (. puts fh str))

  (defn << [fh]
    (. readline fh)))

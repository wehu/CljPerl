(ns quoi

  (require quoi)

  (defn menu [& mappings]
    #[ul
      (reduce (fn [m i]
        (quoi#page (append "/menu/" (append (#:1 m) "$")) (#:2 m))
        (append i (list #[li #[a ^{:href (append "/menu/" (#:1 m))} (#:0 m)]])))
        ()
        mappings)])

  )

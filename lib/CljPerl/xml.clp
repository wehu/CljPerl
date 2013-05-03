(defn xml-translator [cmp-fn xml cb]
  #[(xml-name xml) (map
    (fn [i]
      (if (eq (type i) "xml")
        (if (cmp-fn i) ;equal (#::id (meta i)) id)
          (cb i)
          (xml-translator cmp-fn i cb))
        i))
    xml)])

(defn $ [selector xml cb]
  (let [m (match "#(\\S+)" selector)]
  (if (> (length m) 0)
    (xml-translator (fn [i]
      (equal (#::id (meta i)) (#:0 m)))
      xml cb)
  (let [m (match "\\[([^=]+)=(\\S+)\\]" selector)]
  (if (> (length m) 0)
    (xml-translator (fn [i]
      (equal (#:(#:0 m) (meta i)) (#:1 m)))
      xml cb)
  xml)))))


(require file)

(file#open ">t.txt" (fn [f]
  (file#>> f "aaa")))

(file#open "<t.txt" (fn [f]
  (println (perl->clj (file#<< f)))))

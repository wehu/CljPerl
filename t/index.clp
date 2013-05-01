#[html
  #[body
     #[h1 "hello world"]
     #[ul (map
            (fn [i]
              #[li (append "item " i)])
            (list "a" "b" "c"))]]]

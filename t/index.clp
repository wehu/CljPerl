#[html
  #[body
     #[h1 "hello world"]
     #[ul (map
            (fn [i]
              #[li #[a ^{:href (append "/" i)} (append "item " i)]])
            (list "a" "b" "c"))]]]

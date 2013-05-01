#[html
  #[body
    #[h1 "hello world"]
    #[p "url: " (#::path S)]
    #[p "method: " (#::method S)]
    #[p "params: " (clj->string (#::params S))]
    #[p "headers: " (clj->string (#::headers S))] 
    #[ul (map
           (fn [i]
              #[li #[a ^{:href (append "/" i)} (append "item " i)]])
           (list "a" "b" "c"))]]]

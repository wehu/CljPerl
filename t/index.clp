#[span
  menu
  #[h1 "hello world"]
  (req-info S)
  #[ul (map
         (fn [i]
            #[li #[a ^{:href (append "/" i)} (append "item " i)]])
         alist)]]

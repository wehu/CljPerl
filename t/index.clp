#[span
  menu
  #[h1 "hello world"]
  #[p "url: " (#::path S)]
  #[p "method: " (#::method S)]
  #[p "params: " (clj->string (#::params S))]
  #[p "headers: " (clj->string (#::headers S))] 
  #[p "content: " (clj->string (#::content S))]
  #[p "client host: " (#::client-host S)]
  #[p "client port: " (#::client-port S)]
  #[ul (map
         (fn [i]
            #[li #[a ^{:href (append "/" i)} (append "item " i)]])
         alist)]]

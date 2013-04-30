(require anyevent-httpd)

(anyevent-httpd#start-server {:port 9090}
  {"/" (fn [hd req]
    (anyevent-httpd#respond req
      {"content" ["text/html"
                  (clj->string #[html #[body #[h1 "Hello World!"] #[a ^{:href "/test"} "Another test page"]]])]})) 
  "/test"  (fn [hd req]
    (anyevent-httpd#respond req
      {"content" ["text/html"
                  (clj->string #[html #[body #[h1 "Test Page"] #[a ^{:href "/"} "Back to the main page"]]])]}))})


(require anyevent-httpd)

(anyevent-httpd#start-server {:port 9090}
  {"/"     #[html #[body #[h1 "Hello World!"] #[a ^{:href "/test"} "Another test page"]]]
  "/test"  #[html #[body #[h1 "Test Page"] #[a ^{:href "/"} "Back to the main page"]]]})


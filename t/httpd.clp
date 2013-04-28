(require anyevent-httpd)

(anyevent-httpd#start-server {:port 9090}
  {"/" (fn [hd req]
    (anyevent-httpd#respond req
      {"content" ["text/html"
                  "<html><body><h1>Hello World!</h1><a href=\"/test\">Another test page</a></body></html>"]})) 
  "/test"  (fn [hd req]
    (anyevent-httpd#respond req
      {"content" ["text/html"
                  "<html><body><h1>Test Page</h1><a href=\"/\">Back to the main page</a></body></html>"]}))})


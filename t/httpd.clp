(require anyevent-httpd)

(def s (anyevent-httpd#server {:port 9090}))

(anyevent-httpd#reg-cb s
  {"/" (fn [hd req]
    (anyevent-httpd#respond req
      {"content" ["text/html"
         "<html><body><h1>Hello World!</h1><a href=\"/test\">another test page</a></body></html>"]})) 
  "/test"  (fn [hd req]
    (anyevent-httpd#respond req
      {"content" ["text/html" "<html><body><h1>Test page</h1>
                   <a href=\"/\">Back to the main page</a></body></html>"]}))})

(anyevent-httpd#run s)

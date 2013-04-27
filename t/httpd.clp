(require anyevent-httpd)

(def s (anyevent-httpd#server {:port 9090}))

(anyevent-httpd#reg-cb s
  {"/" (fn [hd req]
    (println req)
    (anyevent-httpd#respond req
      {"content" ["text/html" "hello world"]}))
  "/test"  (fn [hd req]
    (println req)
    (anyevent-httpd#respond req
      {"content" ["text/html" "hello world"]}))})

(anyevent-httpd#run s)

(. require AnyEvent::HTTP)

(->AnyEvent::HTTP http_get "https://www.google.com"
  (fn [data header]
    (println data)
    (println header)))


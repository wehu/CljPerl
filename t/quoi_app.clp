(require quoi)

(quoi#page "/test$"
  #[html #[body "test"]])

(quoi#page "/$"
  "t/index.clp")

(quoi#start {:port 9090})

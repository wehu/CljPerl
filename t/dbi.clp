(require anyevent-dbi)
(require anyevent)

(def cv (anyevent#condvar))

(def db (anyevent-dbi#db "DBI:SQLite:dbname=test.db" "" ""))

(anyevent-dbi#exec db "create table test (name varchar(50))"
  (fn [& args]
    (anyevent-dbi#exec db "select * from test" 
      (fn [& args]
        (println args)
        (anyevent#condvar-send cv)))))

(anyevent#condvar-recv cv)

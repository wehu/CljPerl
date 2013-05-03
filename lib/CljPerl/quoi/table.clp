(ns quoi

  (defn table [ths & rows]
    #[table ^{:class "tablesorter"}
      #[thead
        #[tr
          (map
            (fn [i]
              #[th i])
            ths)
        ]]
      #[tbody
        (map
          (fn [row]
            #[tr
              (map
                (fn [col]
                  #[td col])
                row)])
          rows)]])

  (defn sortable-table [ths & rows]
    #[span
       (apply table (cons ths rows))
       #[script
          "$(document).ready(function(){$('table.tablesorter').tablesorter();});"
        ]])

  )

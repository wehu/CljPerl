(ns quoi

  (require quoi)

  (def ajax-counter 0)

  (defn gen-ajax-id []
    (set! ajax-counter (+ ajax-counter 1))
    (clj->string ajax-counter))

  (defn ajax-button [name S cb js-cb]
    (let [id (gen-ajax-id)]
      (quoi#page (append "/ajax/" (append id "$"))
        (cb S))
        #[span
          #[input ^{:type "submit" :id id :value name}]
          #[script
(append
"
$(document).ready(function(){
  $('#"
(append id (append "').on('click', function(){
  $.ajax({url: '/ajax/" (append id (append "'}).done(" (append
    js-cb
");
})});
"))))))]]))

  )

(ns quoi

  (require quoi)

  (def ajax-counter 0)

  (defn gen-ajax-id []
    (set! ajax-counter (+ ajax-counter 1))
    (clj->string ajax-counter))

  (defn ajax-button [name cb cbs]
    (let [id (gen-ajax-id)]
      (quoi#page (append "/ajax/" (append id "$"))
        (fn [S] (cb S)))
        #[span
          #[input ^{:type "submit" :id id :value name}]
          #[script
(append-list
"
$(document).ready(function(){
  $('#" id "').on('click', function(){
    " (if (equal (#::on-click cbs) nil) "" (#::on-click cbs)) "
  $.ajax({url: '/ajax/" id "'}).done("
    (if (equal (#::ajax-done cbs) nil) "" (#::ajax-done cbs))
  ");
})});
")]]))

  )

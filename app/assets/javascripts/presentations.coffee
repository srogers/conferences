# This takes the Trix buttons out of the tab order so the cursor doesn't go to the buttons and spaces between them.
# Doesn't seem to work on Opera
# http://stackoverflow.com/questions/5243539/how-to-focus-a-form-input-field-when-page-loaded
document.addEventListener("trix-initialize", (event) ->
  for element of event.target.toolbarElement.querySelectorAll("button")
    console.log "fixing trix buttons"
    element.tabIndex = -1
)

$ ->
  $("#add_publication_handle").click ->
    if $(this).hasClass('fa-rotate-90')
      $(this).removeClass('fa-rotate-90')
      $("#publication_form_container").slideUp()
    else
      $(this).addClass('fa-rotate-90')
      $("#publication_form_container").slideDown()

  # First click on the initiator fetches the data, hides the query initiator, and shows the data.
  # Subsequent clicks just show/hide the data area and toggle the button
  $(".detail-selector").on("ajax:success", (event, data, status, xhr) ->
    detail_selector = $(event.currentTarget)
    detail_selector.after xhr.responseText
    detail_selector.children('.detail-initiator').hide()
    detail_selector.children('.detail-hide').show()
    detail_selector.siblings('.details-container').slideDown()
  ).on "ajax:error", (event) ->
    $(".detail-selector").append "<p>ERROR</p>"

  $('.detail-hide').click ->
    clicked = $(this)
    clicked.hide()
    clicked.siblings('.detail-show').show()
    clicked.parent().siblings('.details-container').slideUp()

  $('.detail-show').click ->
    clicked = $(this)
    clicked.hide()
    clicked.siblings('.detail-hide').show()
    clicked.parent().siblings('.details-container').slideDown()

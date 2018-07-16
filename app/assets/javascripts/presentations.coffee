# This takes the Trix buttons out of the tab order so the cursor doesn't go to the buttons and spaces between them.
# Doesn't seem to work on Opera
# http://stackoverflow.com/questions/5243539/how-to-focus-a-form-input-field-when-page-loaded
document.addEventListener("trix-initialize", (event) ->
  for element of event.target.toolbarElement.querySelectorAll("button")
    console.log "fixing trix buttons"
    element.tabIndex = -1
)

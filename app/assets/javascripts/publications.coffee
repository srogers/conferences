get_physical_formats = () ->
  $.map( $(".physical_format").toArray(), ( n, i ) ->  return $(n).text() );

# For forms: set the visibility of the fields for physical media based on the value of the format selector.
# This works for input because of the selector - show manages this field statically
handle_physical_fields = (physical_formats, speed) ->
  if physical_formats.indexOf( $('#publication_format').val() ) > -1
    if speed == 'fast'
      $('#for_physical_publications').show()
    else
      $('#for_physical_publications').slideDown()
  else
    if speed == 'fast'
      $('#for_physical_publications').hide()
    else
      $('#for_physical_publications').slideUp()


$ ->
  # Build an array of the physical format names based on data loaded in the DOM
  physical_formats = get_physical_formats()

  # This sets the correct visibility of ari_inventory and publisher upon landing - do it fast so the user can't see it
  handle_physical_fields(physical_formats, 'fast')

  # This sets the correct visibility of ari_inventory and publisher when the format selector is changed
  $('select#publication_format').change ->
    handle_physical_fields(physical_formats)

  $('#publisher_name').on 'change', ->
    $('#publication_publisher').val(this.value)

  $('#publication_url').on 'blur', ->
    $format_selector = $('#publication_format')
    url =  $('#publication_url').val().toLowerCase()
    if url.includes("youtube.com") or url.includes("youtu.be")
      $format_selector.val("YouTube")
    else if url.includes("facebook.com")
      $format_selector.val("FaceBook")
    else if url.includes("mokuji")
      $format_selector.val("Mokuji")
    else if url.includes("vimeo.com")
      $format_selector.val("Vimeo")
    else if url.includes("campus.aynrand")
      $format_selector.val("Campus")
    else if url.includes("estore.aynrand")
      $format_selector.val("e-Store")

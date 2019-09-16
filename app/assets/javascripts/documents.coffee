$ ->
  # Use radio buttons for CSV generation (only one at a time) vs. checkboxes for PDF (one or more).
  $('select#document_format').change ->
    if $(this).val() == 'PDF'
      $(".form-group#radio_fields").hide()
      $(".form-group#checkbox_fields").show()
      # Disable all the radio buttons so they won't submit - but keep the values
      $(".form-group#checkbox_fields input").prop('disabled', false)
      $(".form-group#radio_fields input").prop('disabled', true)

    if $(this).val() == 'CSV'
      $(".form-group#radio_fields").show()
      $(".form-group#checkbox_fields").hide()
      # Disable all the checkoxes so they won't submit - but keep the values
      $(".form-group#checkbox_fields input").prop('disabled', true)
      $(".form-group#radio_fields input").prop('disabled', false)

  # Force exclusivity onto the radio fields - doesn't happen automatically because they aren't for the same attribute
  $('#document_events_true').click ->
    $("#document_presentations_true").prop('checked', false)
    $("#document_speakers_true").prop('checked', false)
    $("#document_publications_true").prop('checked', false)

  $('#document_presentations_true').click ->
    $("#document_events_true").prop('checked', false)
    $("#document_speakers_true").prop('checked', false)
    $("#document_publications_true").prop('checked', false)

  $('#document_speakers_true').click ->
    $("#document_events_true").prop('checked', false)
    $("#document_presentations_true").prop('checked', false)
    $("#document_publications_true").prop('checked', false)

  $('#document_publications_true').click ->
    $("#document_events_true").prop('checked', false)
    $("#document_presentations_true").prop('checked', false)
    $("#document_speakers_true").prop('checked', false)

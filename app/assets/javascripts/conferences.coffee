# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ ->
  # This is used in Conference and Preseentation to manage the location fields
  set_location_fields = (location) ->
    if location == 'Physical'
      $('.location-conditional-fields').slideDown()
      if $('#conference_venue').val() == 'Virtual' ||  $('#conference_venue').val() == 'Multiple'
        # clear the flag value - otherwise, if the user doesn't change it, the event will still be Virtual/Multiple
        $('#conference_venue').val('')
    if location == 'Virtual'
      $('.location-conditional-fields').slideUp()
      $('#conference_venue').val('Virtual')
    if location == 'Multiple'
      $('.location-conditional-fields').slideUp()
      $('#conference_venue').val('Multiple')

  # This is used by on-change events to set the conference name field to reflect the chosen organizer and start date,
  # But it shouldn't change the name once it's been set. A gon flag is used to wave it off.
  set_conference_name = ->
    return unless typeof gon != 'undefined' and gon.apply_name_default
    parts = $("#conference_organizer_id :selected").text().split(' - ')
    abbreviation = parts[parts.length-1]
    name = abbreviation + ' ' + $('#conference_start_date_1i').val()
    $("#conference_name").val(name)
    $('#conference_name').css("background-color", "yellow")

  set_conference_name() # do it once on page load - TODO pull this from the pipeline and put it on the page where it needs to run

  $("#conference_organizer_id").change ->
    set_conference_name()

  set_location_fields($('#conference_location').val())
  set_location_fields($('#presentation_location').val())

  # Use the location selector to set the venue and show/hide appropriate fields
  $('#conference_location').change ->
    set_location_fields($(this).val())

  # Use the location selector to set the venue and show/hide appropriate fields
  $('#presentation_location').change ->
    set_location_fields($(this).val())

  # Make Start/End date a little less tedious by setting the end dates to the start dates as selected.
  # Then the end date selectors should be in the right general range.
  $('#conference_start_date_1i').change ->
    set_conference_name()
    $('#conference_end_date_1i').val( $('#conference_start_date_1i').val() )

  $('#conference_start_date_2i').change ->
    $('#conference_end_date_2i').val( $('#conference_start_date_2i').val() )

  $('#conference_start_date_3i').change ->
    $('#conference_end_date_3i').val( $('#conference_start_date_3i').val() )

  # This performs autocomplete for selecting a speaker by name for presentations, and selecting a preseentation by name
  # for association in publications/show. It pulls the autocomplete URL from the clicked object, so that paths can be
  # used to set up the URLs on the Rails side.
  $('.select2-autocomplete').each (i, e) ->
    select = $(e)
    options = {
      minimumInputLength: 1
    }

    options.ajax =
      url: select.data('source')
      dataType: 'json'
      delay: 250,
      data: (params) ->
        q: params.term
        # page: 1  # params.page
        # per: 5 - don't change this - let the controller handle it
        exclude: select.data('exclude') # this gets the IDs of the current speakers from data on the selector and passes it so the controller can ignore it
      ,
      processResults: (data, params) ->
        # The controller has to put the data into the format select2 expects with a total and n: {:id , :text}
        # page = params.page || 1
        # per  = params.per  || 5
        return {
          results: data.users,
          pagination: {
            more: false  #  (params.page * per) < data.total
          }
        }

    select.select2 options

# Try to set the minimum number of characters for conference year to 4
#  $('#conference_picker').select2(e) ->
#    select = $(e)
#    options = {
#      minimumInputLength: 4
#    }
#    options.ajax =
#      url: select.data('source')
#      dataType: 'json'
#      delay: 250,
#      data: (params) ->
#        q: params.term
#        page: params.page
#        per: 5
#      ,
#      processResults: (data, params) ->
#        # The controller has to put the data into the format select2 expects with a total and n: {:id , :text}
#        params.page = params.page || 1
#        return {
#          results: data.users,
#          pagination: {
#            more: (params.page * 5) < data.total
#          }
#        }
#
#    select.select2 options

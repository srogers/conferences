# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ ->
  # Make Start/End date a little less tedious by setting the end dates to the start dates as selected.
  # Then the end date selectors should be in the right general range.
  $('#conference_start_date_1i').change ->
    $('#conference_end_date_1i').val( $('#conference_start_date_1i').val() )

  $('#conference_start_date_2i').change ->
    $('#conference_end_date_2i').val( $('#conference_start_date_2i').val() )

  $('#conference_start_date_3i').change ->
    $('#conference_end_date_3i').val( $('#conference_start_date_3i').val() )

  # This performs autocomplete for selecting a speaker by name. It pulls the autocomplete URL from the clicked
  # object, so that paths can be used to describe it on the Rails side.
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
        page: params.page
        per: 5
        exclude: select.data('exclude') # this gets the IDs of the current speakers from data on the selector and passes it so the controller can ignore it
      ,
      processResults: (data, params) ->
        # The controller has to put the data into the format select2 expects with a total and n: {:id , :text}
        params.page = params.page || 1
        return {
          results: data.users,
          pagination: {
            more: (params.page * 5) < data.total
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

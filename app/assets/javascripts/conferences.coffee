# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

# This performs autocomplete for selecting a speaker by name. It pulls the autocomplete URL from the clicked
# object, so that paths can be used to describe it on the Rails side.
$ ->
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
        exclude: select.data('exclude') # this gets the ID of the current concept from data on the selector and passes it in so we can ignore it
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

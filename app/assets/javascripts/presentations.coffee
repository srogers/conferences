# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ ->
  $('#manage_presentation_switch').on 'click', ->
    $('#manage_presentation').toggle(800)

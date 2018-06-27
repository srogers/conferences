// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require bootstrap-sprockets
//= require select2
//  don't require turbolinks because the caching breaks select2
//= require trix
//= require social-share-button
// Everything loads everywhere, so we just suck up all the JS here
//= require_tree .

// For now, activate tooltips everywhere and pass any arguments in the view.
// Tooltip details: http://v4-alpha.getbootstrap.com/components/tooltips/
$(function () {
  $('[data-toggle="tooltip"]').tooltip()
});

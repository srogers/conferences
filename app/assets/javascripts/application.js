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
// Bootstrap requires jquery3, popper - then require either bootstrap-sprockets or bootstrap
//
//= require jquery3
//= require jquery_ujs
//= require jquery-ui/widgets/autocomplete
//= require jquery-ui/widgets/tooltip
//= require popper
//= require bootstrap-sprockets
//= require select2
//=# require chartkick itself, which seems to work without loading Chart.bundle - the individual charts load highcharts or google charts as needed
//= require chartkick
//  don't require turbolinks because the caching breaks select2
//= require trix
//= require social-share-button
//= require cookies_eu
// Everything loads everywhere, so we just suck up all the JS here
//= require_tree .

console.debug("jQuery "+ ($ ? $().jquery : "NOT") +" loaded")
console.debug("Bootstrap version: " + $.fn.tooltip.Constructor.VERSION)

// For now, activate tooltips everywhere and pass any arguments in the view.
// Tooltip details: http://v4-alpha.getbootstrap.com/components/tooltips/
$(function () {
  $('[data-toggle="tooltip"]').tooltip()
});

// Link copy buttons can appear on conference, presentation, publication, or speaker page.
// Grabs the current URL and stuffs it into the paste buffer
$(function() {
  $(".copy_link").on("click", function() {
    temp = $("<textarea style='color: white;'>");
    $("body").append(temp);
    text = window.location.href;
    temp.val(text).select();

    try {
      successful = document.execCommand('copy');
      temp.remove();
      msg = successful ? 'successful' : 'unsuccessful';
      console.log('Copying share URL was ' + msg);
      return false
    }
    catch(err) {
      console.log('Oops, unable to copy share URL', err)
    }
  })
})

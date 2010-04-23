// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
$(document).ready(function() {
  $('input#server_search').quicksearch('#server_list ol li');
  $(".sortable").tablesorter();
  
  $("#search").bind("keyup", function() {
    var form = $(this); // grab the form wrapping the search bar.
    var url = form.attr("action"); // grab the URL from the form's action value.
    var formData = form.serialize(); // grab the data in the form
    $.get(url, formData, function(html) { // perform an AJAX get, the trailing function is what happens on successful get.
      $("#listing").html(html); // replace the "results" div with the result of action taken
    });
  });
  
});
TopUp.images_path = "/images/top_up/";
TopUp.players_path = "/players/";
TopUp.addPresets({
  ".commandstable tbody tr td a": {
    group: "commands",
    type: "ajax",
    layout: "quicklook",
    title: "command",
    x: "0",
    y: "0",
    effect: "flip",
    shaded: 1
  }
});
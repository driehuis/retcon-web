// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
$(document).ready(function() {
  $('input#search_hostname_cont').quicksearch('#server_list ol li', {delay: 100});
  $(".sortable").tablesorter();

  var outstanding = 0;
  $("#search_hostname_cont").bind("keyup", function() {
    outstanding++;
    var url = $(this).attr("action"); // grab the URL from the form's action value.
    var formData = $(this).serialize(); // grab the data in the form
    var jqxhr = $.get(url, formData, function(html) { // perform an AJAX get, the trailing function is what happens on successful get.
      if (outstanding == jqxhr.myGeneration) {
        $("#listing").html(html); // replace the "results" div with the result of action taken
      }
    });
    jqxhr.myGeneration = outstanding;
  });

  $(".toggle").live('click', function(event){
    //alert('.toggle ' + event.target.nodeName);
    if (event.target.nodeName != 'P') { // ignore clicks in paragraphs to allow copy&paste
      $(this).find('.togglable').toggle();
    }
  });
  $(".toggle_settings").live('click', function(){
    $('.togglable').toggle();
  });
});

function remove_fields(link) {
        $(link).prev("input[type=hidden]").val("1");
        $(link).closest(".fields").hide();
}

function add_fields(link, association, content) {
        var new_id = new Date().getTime();
        var regexp = new RegExp("new_" + association, "g");
        $(link).parent().before(content.replace(regexp, new_id));
}

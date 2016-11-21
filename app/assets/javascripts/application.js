//= require jquery
//= require jquery_ujs
//= require jquery.quicksearch
//= require jquery.tablesorter.min

var outstanding = 0;
$(document).ready(function() {
  $(".sortable").tablesorter();

  $('input#search_hostname_cont, input#server_search, input#search_name_cont').each(function(){
    $(this).quicksearch('#server_list ol li', {delay: 100});

    if ($(this).val() && $(this).val().length > 0) {
      get_ajax_content(this)
    }
    $(this).bind("change keyup input", function() {
      get_ajax_content(this)
    });
  });

  $('body').on('click', '.toggle', function(event){
    //alert('.toggle ' + event.target.nodeName);
    if (event.target.nodeName != 'P') { // ignore clicks in paragraphs to allow copy&paste
      $(this).find('.togglable').toggle();
    }
  });
  $('body').on('click', '.toggle_settings', function(){
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

function get_ajax_content(field) {
    outstanding++;
    var url = $(field).attr("action"); // grab the URL from the form's action value.
    var formData = $(field).serialize(); // grab the data in the form
    var jqxhr = $.get(url, formData, function(html) { // perform an AJAX get, the trailing function is what happens on successful get.
      if (outstanding == jqxhr.myGeneration) {
        $("#listing").html(html); // replace the "results" div with the result of action taken
      }
    });
    jqxhr.myGeneration = outstanding;
}

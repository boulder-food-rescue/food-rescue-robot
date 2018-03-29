$("#table_of_volunteers").css("display", "none");
$(document).ready(function(){
    $(".submit").click(function(){
      $("button").removeClass('disabled');
        $("#table_of_volunteers").toggle(1000);
    });
});
$(document).ready(function(){
  $("button").click(function() {
    $(".submit").removeClass('disabled');
    // $("#table_of_volunteers").hide(1000);
    $(this).addClass('disabled');
  });
});
//$(document).ready(function(){
  //$("button").click(function() {
    //$("button").removeClass('disabled');
//  });
//});
//console.log('test');

// $('button#monday').onChange(function(e) {



//$('button#monday').click(function(e) {

  // search for li elements with relevant data
  // .toggle();

// $("#table_of_volunteers").css("display", "none");
$(document).ready(function(){
    $("#submit").click(function(){
        $("#table_of_volunteers").toggle();
    });
});

$(document).ready(function(){
  $('#days').change(function() {
    var day = $("#days option:selected").val();
    alert(day);
  });
});

$(document).ready(function(){
    $('#times').change(function() {
    var time = $("#times option:selected").val();
      alert(time);
  });
});

// Submit button listener
  // $("#submit_button").click(function() {
  //   var day = $('#dropdown_day').val();
  //   var time = $('#dropdown_day').val();
  //
  //
  // })

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

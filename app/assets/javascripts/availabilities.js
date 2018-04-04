$(".availability").css("display", "none");

$('#days').change(function() {
  toggleAvailabilities()
});

$('#times').change(function() {
  toggleAvailabilities()
});

function toggleAvailabilities(){
  var day = $("#days option:selected").val();
  var time = $("#times option:selected").val();
  $(".availability").css("display", "none");
  $('.' + day + '.' + time + '').css("display", "inline");
}
// Reset visible volunteers on page load
toggleAvailabilities()

// Event Listeners
$('#days').change(function() { toggleAvailabilities() });
$('#times').change(function() { toggleAvailabilities() });
$('#btn-grab-emails').click(function() { grabEmails() });

// DOM manipulation
function toggleAvailabilities(){
  var day = $("#days option:selected").val();
  var time = $("#times option:selected").val();
  $(".availability").css("display", "none");
  $('.' + day + '.' + time + '').css("display", "table-row");
}

// Grab currently visible emails and copy them to clipboard as string
function grabEmails(){
  var day = $("#days option:selected").val();
  var time = $("#times option:selected").val();
  var visibleVolunteers = $('.' + day + '.' + time + '');
  var emails = []
  var arrayLength = visibleVolunteers.length;
  for (var i = 0; i < arrayLength; i++) {
    emails.push($(visibleVolunteers[i]).children('.email').html())
  }
  var emailString = emails.join(', ');
  var el = document.createElement('textarea');
  el.value = emailString;
  document.body.appendChild(el);
  el.select();
  document.execCommand('copy');
  document.body.removeChild(el);
  alert("Copied the text: " + emailString);
}

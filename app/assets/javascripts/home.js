var initialize_map = function(){
	var mapOptions = {
	    center: new google.maps.LatLng(40.0149856, -105.2705456),
        zoom: 12,
        mapTypeId: google.maps.MapTypeId.ROADMAP
	};
	var map = new google.maps.Map(document.getElementById("my_recipient_map"), mapOptions);
  }

$(document).ready(function() {
	if ($('#my_recipient_map').length) {
	    initialize_map();
	}
});
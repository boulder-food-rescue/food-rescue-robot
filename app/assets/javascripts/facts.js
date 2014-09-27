$(document).ready(function() {
  $('.fact_info').hide();
  
  $('.text_link').click(function(){
	if( $(this).hasClass('selected')){
	  $(this).removeClass('selected');
	  $(this).next('div').hide();
	}
	else{
	  $(this).addClass('selected');
	  $(this).next('div').show();
	}
  });
});

/**
 * This function will add the section and sub section links to the side bar.
 */
var home_links = function(){
  div = '<ul>\n'
  index = 0
  $('.home_section').each(function(){
	index += 1
	$(this).prepend('<a name="' + index + '"/>')
    section = $($(this).children('h1')[0]).text()
    div += '<li><a href="#' + index + '" class="section_link">' + section + '</a>\n'
    sub_sections = $(this).children('div')
    if(sub_sections.length > 0){
      div += '<ul>\n'
    }
    sub_sections.each(function(e){
      index += 1
      sub_section = $($(this).children('h2')[0]).text()
      div += '<li><a href="#'+index+'">' + sub_section + '</a></li>\n'
      $(this).prepend('<a name="'+index+'"\>')
    })
    if(sub_section.length > 0){
      div += '</ul>\n'
    }
    div += '</li>\n'
  });
  div += '</ul>\n'
  $('.home_sidebar').append(div)
}

var floating_side = function(){
  if($('.home_sidebar').length == 0){
    return;
  }
  w_top = $(window).scrollTop();
  top_size = $('.wrap').offset().top;
  if(w_top >= top_size && !$('.home_sidebar').hasClass('floating')){
    $('.home_sidebar').addClass('floating')
  }
  else if(w_top < top_size){
    $('.home_sidebar').removeClass('floating')
  }
}

/**
 * Setup the minimalist table look
 */
var minimalist_table = function(){
  $('.minamalist_table').each(function(){
    $(this).find('tr').each(function(index, element){
      if(index != 0 && index % 2 == 0)
    	$(element).addClass('even')
    });
  })
}

$(document).ready(function() {
  home_links();
  minimalist_table();
  $(window).scroll(function(){
    floating_side();
  });
  $(window).resize(function(){
    floating_side();
  })
  floating_side();
});
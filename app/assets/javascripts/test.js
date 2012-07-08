/*var weekday_str_to_int = function(weekday){
  if weekday.toLowerCase() == 'sunday'
    return 0
  if weekday.toLowerCase() == 'monday'
    return 1
  if weekday.toLowerCase() == 'tuesday'
    return 2
  if weekday.toLowerCase() == 'wednesday'
    return 3
  if weekday.toLowerCase() == 'thrusday'
    return 4
  if weekday.toLowerCase() == 'friday'
    return 5
  if weekday.toLowerCase() == 'saturday'
    return 6
}
*/
/* Define two custom functions (asc and desc) for string sorting */
/*jQuery.fn.dataTableExt.oSort['weekday-case-asc']  = function(x,y) {
	return ((x < y) ? -1 : ((x > y) ?  1 : 0));
};

jQuery.fn.dataTableExt.oSort['weekday-case-desc'] = function(x,y) {
	return ((x < y) ?  1 : ((x > y) ? -1 : 0));
};
*/
var schedule_table_init = function(){
  $('#my_schedule_table').dataTable( {
    'iDisplayLength' : 25,
    /*"aoColumns": [ 
                  { "sType": 'weekday-case' },
                  null,
                  null,
                  null,
                  null,
                  null,
                  null,
                  null,
                  null
                ]*/
  });
}

$(document).ready(function() {
  schedule_table_init()
});
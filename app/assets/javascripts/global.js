$(document).ready(function() {
  // Setup DataTables
  if( $('#data_table').length > 0 ) {
    window.BFRDataTable = $('#data_table').dataTable({
      'iDisplayLength' : 50,
    });

    $('.dataTables_filter').addClass('form-inline form-group')
                           .find('input[type="search"]')
                           .addClass('form-control');
  }
});

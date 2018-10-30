$(document).ready(function() {
  flatpickr(".datepicker", {
    "dateFormat": "Y-n-j",
    "allowInput": false,
    "onOpen": function(selectedDates, dateStr, instance) {
      instance.setDate(instance.input.value, false);
    }
  });
});

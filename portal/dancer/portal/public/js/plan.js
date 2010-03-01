$(function() {
	$(".plan-guard").draggable({ revert: true });
	$(".plan-action").draggable({ revert: true });

	$(".step-guard").droppable({
	  accept: '.plan-guard',
		drop: function(event, ui) {
			$(this).children('ul').append('<li>'+ui+'</li>');
		}
	});

	$(".step-action").droppable({
	  accept: '.plan-action',
		drop: function(event, ui) {
			$(this).children('ul').append('<li>'+ui+'</li>');
		}
	});

	$(".step-guard-items").sortable({ placeholder: 'ui-state-highlight' });
	$(".step-action-items").sortable({ placeholder: 'ui-state-highlight' });

  $("#plan").sortable({
	  placeholder: 'ui-state-highlight'
  });

});

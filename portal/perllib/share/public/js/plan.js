$(function() {
  $(".plan-guard").draggable({ revert: true });
  $(".plan-action").draggable({ revert: true });

  $(".step-guard").droppable({
    accept: '.plan-guard',
    activeClass: 'ui-state-hover',
    hoverClass: 'ui-state-hover',
    drop: function(event, ui) {
      var d = ui['draggable'];
      $(this).children('ul').append('<li>'+d.html()+'</li>');
    }
  });

  $(".step-action").droppable({
    accept: '.plan-action',
    activeClass: 'ui-state-hover',
    hoverClass: 'ui-state-hover',
    drop: function(event, ui) {
      var d = ui['draggable'];
      $(this).children('ul').append('<li>'+d.html()+'</li>');
    }
  });

  $(".items").sortable({ placeholder: 'ui-state-highlight' });

  $("#plan").sortable({
    placeholder: 'ui-state-highlight'
  });

});

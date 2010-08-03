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

  var prefix     = $("#prefix").val();
  var plan_name  = $("#plan_name").val();

  var guards_holder  = '<div class="step-guard ui-widget-header"><p>Guards</p><ul class="items"></ul></div>';
  var actions_holder = '<div class="step-action ui-widget-header"><p>Actions</p><ul class="items"></ul></div>';
  var step_holder    = '<li>'+guards_holder+actions_holder+'</li>';

  /* Load the data from the server */
  $.getJSON( prefix+'/json/billing/billing_plan', { plan_name: plan_name }, function(data){
    var step;
    /* Remove all child nodes */
    $("#plan").empty();

    var rating_steps = data.rating_steps;
    for (step in rating_steps) {
      $("#plan").append(step_holder);
      var guard;
      for (guard  in step.guards) {
        /* each guard is an array: [ name, p0, p1, .. ] */
        var name = guard.shift();

        /* Copy the template for this name */
        $("#name").clone().appendTo("#plan > li:last-child > .step-guard > ul");

        /* Populate the parameters */
        var i;
        for (i=0;i<guard.length;i++) {
          var selector = "#plan > li:last-child > .step-guard > ul input,select[name='p"+i+"']";
          $(selector).val(guard[i]);
        }
      }
      var action;
      for (action in step.actions) {
        /* each action is an array: [ name, p0, p1, .. ] */
        var name = action.shift();

        /* Copy the template for this name */
        $("#name").clone().appendTo("#plan > li:last-child > .step-action > ul");

        /* Populate the parameters */
        var i;
        for (i=0;i<guard.length;i++) {
          var selector = "#plan > li:last-child > .step-action > ul input,select[name='p"+i+"']";
          $(selector).val(guard[i]);
        }
      }
    }
  });

  $("#add_step").click(function(ev){
     $("#plan").append(step_holder);
  });

  $("#submit_steps").click(function(ev){
    /* XXX collect nodes */
    var rating_steps = [];

    $.post( prefix+'/json/billing/billing_plan', { plan_name: plan_name, rating_steps: rating_steps }, function(data){
      /* we will get { ok: "true" } iff everything went OK */
    });
  });
});

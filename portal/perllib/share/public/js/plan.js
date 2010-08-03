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

    /* Remove all child nodes */
    $("#plan").empty();

    var step_i;
    for (step_i in data.rating_steps) {
      var step = data.rating_steps[step_i];

      $("#plan").append(step_holder);

      var guard_i;
      for (guard_i  in step.guards) {
        var guard = step.guards[guard_i];

        /* each guard is an array: [ name, p0, p1, .. ] */
        var name = guard.shift();

        /* Copy the template for this name */
        $("#name").clone().appendTo("#plan > li:last-child > .step-guard > ul");

        /* Populate the parameters */
        for (i in guard) {
          var selector = "#plan > li:last-child > .step-guard > ul input,select[name='p"+i+"']";
          $(selector).val(guard[i]);
        }
      }

      var action_i;
      for (action_i in step.actions) {
        var action = step.actions[action_i];

        /* each action is an array: [ name, p0, p1, .. ] */
        var name = action.shift();

        /* Copy the template for this name */
        $("#name").clone().appendTo("#plan > li:last-child > .step-action > ul");

        /* Populate the parameters */
        var i;
        for (i in action) {
          var selector = "#plan > li:last-child > .step-action > ul input,select[name='p"+i+"']";
          $(selector).val(action[i]);
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

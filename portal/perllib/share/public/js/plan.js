$(function() {
  $(".plan-guard").draggable({ revert: true });
  $(".plan-action").draggable({ revert: true });

  var set_class = function() {
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
  };

  var prefix     = $("#prefix").val();
  var plan_name  = $("#plan_name").val();

  var guards_holder  = '<div class="step-guard ui-widget-header"><p>Guards</p><ul class="items"></ul></div>';
  var actions_holder = '<div class="step-action ui-widget-header"><p>Actions</p><ul class="items"></ul></div>';
  var step_holder    = guards_holder+actions_holder;

  var guard_selector  = "#plan > li:last-child > .step-guard  > ul";
  var action_selector = "#plan > li:last-child > .step-action > ul";

  /* Load the data from the server */
  $.getJSON( prefix+'/json/billing/billing_plan', { plan_name: plan_name }, function(data){

    /* Remove all child nodes */
    $("#plan").empty();

    var step_i;
    for (step_i in data.rating_steps) {
      var step = data.rating_steps[step_i];

      $("#plan").append('<li>'+step_holder+'</li>');

      var guard_i;
      for (guard_i  in step.guards) {
        var guard = step.guards[guard_i];

        /* each guard is an array: [ name, p0, p1, .. ] */
        var name = guard.shift();

        $(guard_selector).append("<li></li>");

        /* Copy the template for this name */
        $("#"+name).clone().children().appendTo(guard_selector+" > li");

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

        $(action_selector).append("<li></li>");

        /* Copy the template for this name */
        $("#"+name).clone().children().appendTo(action_selector+" > li");

        /* Populate the parameters */
        var i;
        for (i in action) {
          var selector = "#plan > li:last-child > .step-action > ul input,select[name='p"+i+"']";
          $(selector).val(action[i]);
        }
      }
    }
    set_class();
  });

  $("#add_step").click(function(ev){
     $("#plan").append('<li>'+step_holder+'</li>');
     set_class();
  });

  $("#submit_steps").click(function(ev){
    var rating_steps = [];

    /* For each step ... */
    $("#plan > li").each(function(step_i){
      var guards  = [];
      var actions = [];

      /* Collect the guards and their parameters */
      $(".step-guard > ul > li",this).each(function(guard_i){
        guards[guard_i] = [];
        var i;
        for(i=0;i<=2;i++) {
          var v = $("[name='p"+i+"']",this);
          if(v) guards[guard_i][i] = v.val();
        }
      });
      /* Collect the actions and their parameters */
      $(".step-action > ul > li",this).each(function(action_i){
        actions[action_i] = [];
        var i;
        for(i=0;i<=2;i++) {
          var v = $("[name='p"+i+"']",this);
          if(v) actions[action_i][i] = v.val();
        }
      });
      /* Skip any node that has no actions (it's OK to not have guards) */
      if(actions.length) {
        rating_steps[step_i] = { guards: guards, actions: actions };
      }
    });

    rating_steps = JSON.stringify(rating_steps);

    $.post( prefix+'/json/billing/billing_plan', { plan_name: plan_name, rating_steps: rating_steps }, function(data){
      /* we will get { ok: "true" } iff everything went OK */
    });
  });
});

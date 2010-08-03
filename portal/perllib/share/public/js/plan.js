$(function() {
  $(".plan-guard").draggable({ revert: true });
  $(".plan-action").draggable({ revert: true });

  var remove_span = '<span title="Remove" class="remove ui-icon ui-icon-circle-minus">(remove)</span>';

  var set_class = function() {
    $(".step-guard").droppable({
      accept: '.plan-guard',
      activeClass: 'ui-state-hover',
      hoverClass: 'ui-state-hover',
      drop: function(event, ui) {
        var d = ui['draggable'];
        $(this).children('ul').append('<li>'+remove_span+d.html()+'</li>');
      }
    });

    $(".step-action").droppable({
      accept: '.plan-action',
      activeClass: 'ui-state-hover',
      hoverClass: 'ui-state-hover',
      drop: function(event, ui) {
        var d = ui['draggable'];
        $(this).children('ul').append('<li>'+remove_span+d.html()+'</li>');
      }
    });

    $(".items").sortable({ placeholder: 'ui-state-highlight' });

    $("#plan").sortable({
      placeholder: 'ui-state-highlight'
    });

    $("#plan .remove").click(function(ev){
      $(this).closest("li").remove();
    });
  };

  var prefix     = $("#prefix").val();
  var plan_name  = $("#plan_name").val();

  var step_header    = '<div class="step-header ui-widget-header">'+remove_span+'Step</div>';
  var guards_holder  = '<div class="step-guard ui-widget"><p>Guards</p><ul class="items"></ul></div>';
  var actions_holder = '<div class="step-action ui-widget"><p>Actions</p><ul class="items"></ul></div>';
  var step_holder    = '<li>'+step_header+guards_holder+actions_holder+'</li>';

  var guard_selector  = "#plan > li:last-child > .step-guard  > ul";
  var action_selector = "#plan > li:last-child > .step-action > ul";

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

        /* each guard is an array: [ name, p1, p2, .. ] */
        var name = guard[0];

        $(guard_selector).append('<li>'+remove_span+'</li>');

        /* Copy the template for this name */
        $("#"+name).clone().children().appendTo(guard_selector+" > li:last-child");

        /* Populate the parameters */
        for (i in guard) {
          var selector;
          selector = guard_selector + " > li:last-child input[name='p"+i+"']";
          $(selector).val(guard[i]);
          selector = guard_selector + " > li:last-child select[name='p"+i+"']";
          $(selector).val(guard[i]);
        }
      }

      var action_i;
      for (action_i in step.actions) {
        var action = step.actions[action_i];

        /* each action is an array: [ name, p1, p2, .. ] */
        var name = action[0];

        $(action_selector).append('<li>'+remove_span+'</li>');

        /* Copy the template for this name */
        $("#"+name).clone().children().appendTo(action_selector+" > li:last-child");

        /* Populate the parameters */
        var i;
        for (i in action) {
          var selector;
          selector = action_selector + " > li:last-child input[name='p"+i+"']";
          $(selector).val(action[i]);
          selector = action_selector + " > li:last-child select[name='p"+i+"']";
          $(selector).val(action[i]);
        }
      }
    }
    set_class();
  });

  $("#add_step").click(function(ev){
     $("#plan").append(step_holder);
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
          var v = $("[name='p"+i+"']",this).val();
          if(v) guards[guard_i][i] = v;
        }
      });
      /* Collect the actions and their parameters */
      $(".step-action > ul > li",this).each(function(action_i){
        actions[action_i] = [];
        var i;
        for(i=0;i<=2;i++) {
          var v = $("[name='p"+i+"']",this).val();
          if(v) actions[action_i][i] = v;
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
      if(data.ok) {
        $("#history").append('(<a href="'+prefix+'/request/'+data.request+'">Check</a>) ');
      }
    });
  });
});

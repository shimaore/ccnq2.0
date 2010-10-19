$(function() {
  var refresh;
  refresh = function(view,page_offset) {
    var current_page  = 0 + view.find(".current_page").html() || 1;
    var limit         = 0 + view.find(".per_page").val()      || 25;

    var new_page = current_page + page_offset;
    var url = "?page="+new_page+"&limit="+limit;

    view.find(".view_content").load(url, function(){
      view.find(".prev_page").click(function(){
        refresh(view,-1);
        return;
      });
      view.find(".next_page").click(function(){
        refresh(view,+1);
        return;
      });
      view.find(".per_page").change(function(){
        var new_limit = 0 + view.find(".per_page").val();
        var same_page = Math.floor((new_page * limit) / new_limit);
        refresh(view,same_page.-current_page);
      });
    });
  };

  // Initiliaze the view
  $(".view").each(function(){
    refresh($(this),0);
  });
});

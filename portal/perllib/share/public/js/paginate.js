$(function() {
  var refresh;
  refresh = function(view,page_offset) {
    var current_page  = view.children(".current_page").html() || 1;
    var limit         = view.children(".per_page").val()      || 25;

    var new_page = current_page + page_offset;
    var url = "?page="+new_page+"&limit="+limit;

    view.children(".view_content").load(url, function(){
      view.children(".prev_page").onclick(function(){
        refresh(view,-1);
      });
      view.children(".next_page").onclick(function(){
        refresh(view,+1);
      });
      view.children(".next_page").onclick(function(){
        refresh(view,+1);
      });
      view.children(".per_page").onclick(function(){
        var new_limit = view.children(".per_page").val();
        var same_page = (new_page / limit) * new_limit;
        refresh(view,same_page-current_page);
      });
    });
  };

  // Initiliaze the view
  $(".view").each(function(){
    refresh($(this),0);
  });
});

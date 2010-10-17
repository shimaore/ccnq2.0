$(function() {
  var cache = {};
  var lastXhr;

  $( "#numbers" ).autocomplete({
    minLength: 2,
    source: function( request, response ) {
      var term = request.term;
      if ( term in cache ) {
        response( cache[ term ] );
        return;
      }

      lastXhr = $.getJSON( prefix+"/numbers.json", request, function( data, status, xhr ) {
        cache[ term ] = data;
        if ( xhr === lastXhr ) {
          response( data );
        }
      });
    }
  });
});

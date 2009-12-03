
# See also Path::Dispatcher::Declarative  ?

# XXX Rewrite node/api/actions.pm et al. to use JSON-RPC naming (i.e. "method" instead of "action", "result" instead of "params" for responses)

sub make_couchdb_proxy {
  my ($context,$couch_db,$readable_fields,$writable_fields) = @_;

  return sub {
    my ($httpd, $req) = @_;

    debug("node/account: Processing web request");

    use URI;
    my $url = URI->new($req->url);
    my $path = $url->path;
    my @path = split(m{/},$path);

    if( defined($path[1]) ) {
      $body->{params}->{account} = $path[1];
    } else {
      $req->respond([404,'Invalid request']);
      $httpd->stop_request;
      return;
    }

    ### XXX Get the record from the DB

      if($req->method eq 'GET') {

        if( defined($path[2]) ) {

          my $field = $path[2];
          if(!grep { $_ eq $path[2] } @{$readable_fields}) {
            $req->respond([501,'Invalid method']);
            $httpd->stop_request;
            return;
          }

          if(exists($doc->{$field})) {
            my $json_content = encode_json($doc->{$field});
            debug("node/account: Return value: $json_content");
            $req->respond([200,'OK',{ 'Content-Type' => 'text/json' },$json_content]);
          } else {
            debug("node/account: Return value: undef");
            $req->respond([204,'No content']);
          }

        } else {

          my $json_content = encode_json($doc);
          debug("node/account: Return value: $json_content");
          $req->respond([200,'OK',{ 'Content-Type' => 'text/json' },$json_content]);

        }

      } elsif($req->method eq 'PUT') {

        if( defined($path[2]) ) {

          my $field = $path[2];
          if(!grep { $_ eq $path[2] } @{$writable_fields}) {
            $req->respond([501,'Invalid method']);
            $httpd->stop_request;
            return;
          }

          $doc->{$field} = $req->vars->{value};

        } else {

          foreach my $field ($writable_fields) {
            $doc->{$_} = $req->vars->{$field};
          }
        }
        # XXX Save the new record

      } else {
        $req->respond([501,'Invalid method']);
        $httpd->stop_request;
        return;
      }
  };
}

1;

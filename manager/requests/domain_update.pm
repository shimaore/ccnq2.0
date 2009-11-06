sub {
  my $request = shift;
  debug("domain_update request");
  # Return list of activities required to complete this request.
  return (
    {
      action => 'domain/update',
      cluster_name => $request->{cluster_name},
      params => {
        map { $_ => $request->{$_} } qw( domain )
      }
    },
    {
      action => 'restart_proxy',
      cluster_name => $request->{cluster_name},
    }
  );
}

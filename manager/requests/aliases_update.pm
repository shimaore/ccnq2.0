sub {
  my $request = shift;
  debug("aliases_update request");
  # Return list of activities required to complete this request.
  return (
    {
      action => 'aliases/update',
      cluster_name => $request->{cluster_name},
      params => {
        map { $_ => $request->{$_} } qw( username domain target_username target_domain )
      }
    },
  );
}

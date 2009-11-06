sub {
  my $request = shift;
  debug("update_dr_gateway request");
  # Return list of activities required to complete this request.
  return (
    {
      action => 'dr_gateway/update',
      cluster_name => $request->{cluster_name},
      params => {
        map { $_ => $request->{$_} } qw( target strip_digit prefix realm login password )
      }
    },
    {
      action => 'dr_reload',
      cluster_name => $request->{cluster_name},
    }
  );
}
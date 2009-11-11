sub {
  my $request = shift;
  # Return list of activities required to complete this request.
  return (
    {
      action => 'dr_rule/delete',
      cluster_name => $request->{cluster_name},
      params => {
        map { $_ => $request->{$_} } qw( outbound_route prefix priority )
      }
    },
    {
      action => 'dr_reload',
      cluster_name => $request->{cluster_name},
    }
  );
}
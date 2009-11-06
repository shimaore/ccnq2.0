sub {
  my $request = shift;
  debug("update_dr_rule request");
  # Return list of activities required to complete this request.
  return (
    {
      action => 'dr_rule/update',
      cluster_name => $request->{cluster_name},
      params => {
        map { $_ => $request->{$_} } qw( group description prefix priority target )
      }
    },
    {
      action => 'dr_reload',
      cluster_name => $request->{cluster_name},
    }
  );
}
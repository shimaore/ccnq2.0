sub {
  my $request = shift;
  # Return list of activities required to complete this request.
  return (
    {
      action => 'inbound/delete',
      cluster_name => $request->{cluster_name},
      params => {
        map { $_ => $request->{$_} } qw( source )
      }
    },
    {
      action => 'trusted_reload',
      cluster_name => $request->{cluster_name},
    }
  );
}

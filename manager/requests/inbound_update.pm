sub {
  my $request = shift;
  debug("update_subscriber request");
  # Return list of activities required to complete this request.
  return (
    {
      action => 'inbound/update',
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

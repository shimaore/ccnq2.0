sub {
  my $request = shift;
  # Return list of activities required to complete this request.
  return (
    {
      action => 'local_number/update',
      cluster_name => $request->{cluster_name},
      params => {
        map { $_ => $request->{$_} } qw( number domain username username_domain cfa cfnr cfb cfda cfda_timeout outbound_route account account_sub )
      }
    },
  );
}

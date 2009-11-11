sub {
  my $request = shift;
  # Return list of activities required to complete this request.
  return (
    {
      action => 'domain/update',
      cluster_name => $request->{cluster_name},
      params => {
        map { $_ => $request->{$_} } qw( domain )
      }
    },
  );
}

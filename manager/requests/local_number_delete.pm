sub {
  my $request = shift;
  # Return list of activities required to complete this request.
  return (
    {
      action => 'local_number/delete',
      cluster_name => $request->{cluster_name},
      params => {
        map { $_ => $request->{$_} } qw( number domain )
      }
    },
  );
}

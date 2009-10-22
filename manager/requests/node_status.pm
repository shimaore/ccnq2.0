sub {
  my $request = shift;
  # Return list of activities required to complete this request.
  return (
    {
      action => 'status',
      node_name => $request->{node_name},
    },
  );
}
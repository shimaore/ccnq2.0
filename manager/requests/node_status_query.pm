sub {
  my $request = shift;
  debug("node_status request");
  # Return list of activities required to complete this request.
  return (
    {
      action => 'status',
      node_name => $request->{node_name},
    },
  );
}
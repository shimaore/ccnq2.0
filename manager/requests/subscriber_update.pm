sub {
  my $request = shift;
  debug("update_subscriber request");
  # Return list of activities required to complete this request.
  return (
    {
      action => 'subscriber/update',
      cluster_name => $request->{cluster_name},
      params => {
        map { $_ => $request->{$_} } qw( username domain password ip port srv recording strip_digit default_npa account allow_local allow_ld allow_premium allow_international always_proxy_media )
      }
    },
  );
}

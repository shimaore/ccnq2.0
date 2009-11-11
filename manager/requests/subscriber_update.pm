sub {
  my $request = shift;
  # Return list of activities required to complete this request.
  return (
    {
      action => 'subscriber/update',
      cluster_name => $request->{cluster_name},
      params => {
        map { $_ => $request->{$_} } qw( username domain password ip port srv dest_domain strip_digit account account_sub allow_onnet always_proxy_media )
      }
    },
  );
}

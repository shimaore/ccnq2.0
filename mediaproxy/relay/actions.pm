{
  install => sub {
    my ($params,$context) = @_;
    use CCNQ::MediaProxy;
    CCNQ::MediaProxy::install_default_key('relay');

    my $cluster_fqdn = CCNQ::Install::cluster_fqdn($params->{cluster_name});

    my $config = <<"EOT";
# start relay configuration

[Relay]
dispatchers = ${cluster_fqdn}
passport = None
;relay_ip = <default host IP>
port_range = 40000:41998
;log_level = DEBUG
;stream_timeout = 90
;on_hold_timeout = 7200
;dns_check_interval = 60
;reconnect_delay = 10
;traffic_sampling_period = 15

# end relay configuration
EOT
    print_to(CCNQ::MediaProxy::mediaproxy_config.'.relay',$config);
  }
}
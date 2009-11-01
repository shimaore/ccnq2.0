{
  install => sub {
    use CCNQ::MediaProxy;
    CCNQ::MediaProxy::install_default_key('dispatcher');
    my $config = <<EOT;
# start dispatcher configuration

[Dispatcher]
socket_path = /var/run/mediaproxy/dispatcher.sock
;listen = 0.0.0.0
;listen_management = 0.0.0.0
;management_use_tls = yes
passport = None
;management_passport = None
;log_level = DEBUG
;relay_timeout = 5
;accounting =

[OpenSIPS]
;socket_path = /var/run/opensips/socket
;max_connections = 10

# end dispatcher configuration
EOT
    print_to(CCNQ::MediaProxy::mediaproxy_config.'.dispatcher',$config);
  }
}
{
  install => sub {
    use CCNQ::MediaProxy;
    use File::Spec;
    use File::Copy;
    for my $file (qw( ca.pem crl.pem )) {
      my $src = File::Spec->catfile(CCNQ::MediaProxy::mediaproxy_directory,$file);
      my $dst = File::Spec->catfile(CCNQ::MediaProxy::mediaproxy_install_conf,'tls',$file);
      CCNQ::MediaProxy::try_install($src,$dst);
    }
    my $dispatcher_file = CCNQ::MediaProxy::mediaproxy_config.'.dispatcher';
    my $relay_file      = CCNQ::MediaProxy::mediaproxy_config.'.relay';
    my $config_dispatcher = -f($dispatcher_file) ? CCNQ::Install::content_of($dispatcher_file) : '';
    my $config_relay      = -f($relay_file)      ? CCNQ::Install::content_of($relay_file)      : '';
    my $config = <<'EOT';
[TLS]
certs_path = /etc/mediaproxy/tls
;verify_interval = 300

[Database]
;dburi = mysql://mediaproxy:CHANGEME@localhost/mediaproxy
;sessions_table = media_sessions
;callid_column = call_id
;fromtag_column = from_tag
;totag_column = to_tag
;info_column = info

[Radius]
;config_file = /etc/opensips/radius/client.conf
;additional_dictionary = radius/dictionary

EOT
    print_to(CCNQ::MediaProxy::mediaproxy_config,$config.$config_dispatcher.$config_relay);
    unlink($dispatcher_file);
    unlink($relay_file);
  }
}
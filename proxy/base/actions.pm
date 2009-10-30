use CCNQ::Proxy;
use lib CCNQ::Proxy::proxy_base_lib;
use CCNQ::Proxy::Config;

{
  install => sub {

    use constant proxy_mode => 'proxy_mode';
    use constant proxy_mode_file => File::Spec->catfile(CCNQ::Install::CCN,proxy_mode);

    # MODEL: Which model is used for the local opensips system
    # Must be onre of the *.recipe names:
    #    complete-transparent
    #    complete
    #    inbound-proxy
    #    outbound-proxy
    #    registrar
    #    router-no-registrar
    #    router

    my $model = first_line_of(proxy_mode_file);
    my $template_dir = CCNQ::Install::CCN;

    # We install opensips.cfg and opensips.sql into /etc/ccn/
    my $SRC = CCNQ::Install::SRC;

    # Reconfigure the local system (includes installing the new opensips.cfg file in /etc/opensips)
    info("Reconfiguring the local system");
    eval { CCNQ::Proxy::Config::configure_opensips($model); };
    info($@) if $@;

    # Restart OpenSIPS using the new configuration.
    info("Restarting OpenSIPS");
    CCNQ::Install::_execute('/bin/sed','-i','-e','s/^RUN_OPENSIPS=no$/RUN_OPENSIPS=yes/','/etc/default/opensips');
    CCNQ::Install::_execute('/etc/init.d/opensips','restart');
  },
}
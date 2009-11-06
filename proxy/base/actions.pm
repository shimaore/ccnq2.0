use CCNQ::Proxy;
use lib CCNQ::Proxy::proxy_base_lib;
use CCNQ::Proxy::Config;

{
  install => sub {
    my ($params,$context) = @_;

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
    die if !defined $model;
    my $template_dir = CCNQ::Install::CCN;

    # We install opensips.cfg and opensips.sql into /etc/ccn/
    my $SRC = CCNQ::Install::SRC;

    # Reconfigure the local system (includes installing the new opensips.cfg file in /etc/opensips)
    info("Reconfiguring the local system");
    eval { CCNQ::Proxy::Config::configure_opensips($context,$model); };
    info($@) if $@;

    # Restart OpenSIPS using the new configuration.
    info("Restarting OpenSIPS");
    CCNQ::Install::_execute($context,'/bin/sed','-i','-e','s/^RUN_OPENSIPS=no$/RUN_OPENSIPS=yes/','/etc/default/opensips');
    CCNQ::Install::_execute($context,'/etc/init.d/opensips','restart');
    return;
  },

  _session_ready => sub {
    my ($params,$context) = @_;
    use CCNQ::XMPPAgent;
    debug("Proxy _session_ready");
    CCNQ::XMPPAgent::join_cluster_room($context);
    return;
  },

  _default => sub {
    my ($action,$request,$context) = @_;
    error("No action defined"), return unless $action;
    my ($module,$command) = ($action =~ m{^(.*)/(delete|update|query)$});
    error("Invalid action $action"), return unless $module && $command;

    debug("Ignoring response") if $request->{status};

    use CCNQ::Proxy::Configuration;
    my $cv = CCNQ::Proxy::Configuration::run_from_class($module,$command,$request->{params},$context);
    $context->{condvar}->cb($cv) if $cv;
    return;
  },

  dr_reload => sub {
    my ($params,$context) = @_;
    CCNQ::Install::_execute($context,qw( /usr/sbin/opensipsctl fifo dr_reload ));
    return;
  }
}

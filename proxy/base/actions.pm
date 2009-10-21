use constant runtime_opensips_cfg => '/etc/opensips/opensips.cfg';
use constant template_opensips_cfg => File::Spec->catfile(CCNQ::Install::CCN,'opensips.cfg');
use constant proxy_base_lib => File::Spec->catfile(CCNQ::Install::SRC,qw( proxy base lib ));

sub configure_opensips {
  use lib proxy_base_lib;
  use CCNQ::Proxy::Base;

  require (CCNQ::Install::CCN.'configuration.pm');

  my $CONFIG   = runtime_opensips_cfg;
  my $TEMPLATE = template_opensips_cfg;

  rename $CONFIG, "$CONFIG.bak";

  open(my $fh,'<',$TEMPLATE) or die "open $TEMPLATE: $!";
  open(my $fout,'>',$CONFIG) or die "open $CONFIG: $!";

  my %avps = %{CCNQ::Proxy::Base::avp()};

  # -----------------------
  #   CDR_EXTRA
  # -----------------------

  my @cdr_extra = ();
  my @cdr_src = @{CCNQ::Proxy::Base::cdr_extra()};
  while(@cdr_src)
  {
      my $name = shift @cdr_src;
      my $var  = shift @cdr_src;
      push @cdr_extra, "$name=$var";
  }
  undef @cdr_src;

  # -----------------------
  #   RADIUS_EXTRA
  # -----------------------

  my @radius_extra = ();
  my @radius_src = @{CCNQ::Proxy::Base::radius_extra()};
  while(@radius_src)
  {
      my $name = shift @radius_src;
      my $var  = shift @radius_src;
      push @radius_extra, "$name=$var";
  }
  undef @radius_src;

  my %values = (
      PROXY_IP    => $configuration::sip_host,
      PROXY_PORT  => $configuration::sip_port,
      CHALLENGE   => $configuration::sip_challenge,
      DB_URL      => "mysql://${configuration::db_login}:${configuration::db_password}\@${configuration::db_host}/${configuration::db_name}",
      AVP_ALIASES => join(';',map { "$_=I:$avps{$_}" } (sort keys %avps)),
      CDR_EXTRA   => join(';',@cdr_extra),
      RADIUS_EXTRA   => join(';',@radius_extra),
      NANPA       => 1,
      FR          => 0,
      MPATH       => defined $configuration::mpath ? $configuration::mpath : '/usr/lib/opensips/modules/',
      RADIUS_CONFIG => defined $configuration::radius_config ? $configuration::radius_config : '',
      DEBUG       => defined $configuration::debug ? $configuration::debug : 3,
      MP_ALLOWED  => defined $configuration::mp_allowed ? $configuration::mp_allowed : 1,
      MP_ALWAYS   => defined $configuration::mp_always ? $configuration::mp_always : 0,
      MAX_HOPS    => (defined $configuration::max_hops && $configuration::max_hops ne '') ? $configuration::max_hops : '10',
      # If multiple servers are chained it may be necessary to use different names for the VSF parameter.
      UAC_VSF     => (defined $configuration::uac_vsf && $configuration::uac_vsf ne '') ? $configuration::uac_vsf : 'vsf',
      NODE_ID     => $configuration::node_id || '',
      INV_TIMER   => $configuration::inv_timer || 60,
  );

  $configuration::accounting = 'flatstore'
      if not defined $configuration::accounting;
  $configuration::authenticate = 'db'
      if not defined $configuration::authenticate;

  my $accounting_pattern   = '#IF_ACCT_'.uc($configuration::accounting);
  my $authenticate_pattern = '#IF_AUTH_'.uc($configuration::authenticate);

  while(<$fh>)
  {
      s/\$\{([A-Z_]+)\}/defined $values{$1} ? $values{$1} : warn "Undefined $1"/eg;
      s/^\s*${accounting_pattern}//;
      s/^\s*${authenticate_pattern}//;
      s/^\s*#IF_USE_NODE_ID// if $configuration::node_id;
      s/^\s*#USE_PROXY_IP\s*// if $configuration::sip_host;
      print $fout $_;
  }

  info(<<TXT);
Please run the following commands:
mysql <<SQL
  CREATE DATABASE ${configuration::db_name};
  CONNECT ${configuration::db_name};
  CREATE USER ${configuration::db_login} IDENTIFIED BY '${configuration::db_password}';
  GRANT ALL ON ${configuration::db_name}.* TO ${configuration::db_login};
SQL

mysql ${configuration::db_name} < ${CCNQ::Install::CCN}/opensips.sql

TXT

}

{
  install => sub {

    use constant proxy_mode => 'proxy_mode';
    use constant proxy_mode_file => File::Spec->catfile(CCN,proxy_mode);

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

    # Generate a new opensips.cfg and opensips.sql file and push them
    info("Generating a new opensips.cfg and opensips.sql");
    CCNQ::Install::_execute("cd ${SRC}/proxy/base/opensips && ./build.sh ${model} ${template_dir}");

    # Reconfigure the local system (includes installing the new opensips.cfg file in /etc/opensips)
    info("Reconfiguring the local system");
    eval { configure_opensips(); };
    info($@) if $@;

    # Restart OpenSIPS using the new configuration.
    info("Restarting OpenSIPS");
    CCNQ::Install::_execute("sudo /etc/init.d/opensips restart");
  },
}
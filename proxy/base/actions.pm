use File::Temp;

use constant runtime_opensips_cfg => '/etc/opensips/opensips.cfg';
use constant runtime_opensips_sql => '/etc/opensips/opensips.sql';

use constant proxy_base_lib => File::Spec->catfile(CCNQ::Install::SRC,qw( proxy base lib ));
use constant opensips_base_lib => File::Spec->catfile(CCNQ::Install::SRC,qw( proxy base opensips));

sub configure_opensips {
  my ($model) = @_;

  use lib proxy_base_lib;
  use CCNQ::Proxy::Base;
  use CCNQ::Proxy::Config;

  # Use sensible defaults if no configuration.pm is found.
  eval { require (CCNQ::Install::CCN.'/configuration.pm'); };
  warning($@) if $@;

  # Evaluate the parameters
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
      PROXY_IP    => $configuration::sip_host || '',
      PROXY_PORT  => $configuration::sip_port || '',
      CHALLENGE   => $configuration::sip_challenge || '',
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

  # End of parameters

  my $template_text = CCNQ::Proxy::Config::compile_cfg(opensips_base_lib,$model);
  my $sql_text      = CCNQ::Proxy::Config::compile_sql(opensips_base_lib,$model);

  my $template = new IO::Scalar \$template_text;

  my $cfg_text = '';
  while(<$template>)
  {
      s/\$\{([A-Z_]+)\}/defined $values{$1} ? $values{$1} : (warning("Undefined $1"),'')/eg;
      s/^\s*${accounting_pattern}//;
      s/^\s*${authenticate_pattern}//;
      s/^\s*#IF_USE_NODE_ID// if $configuration::node_id;
      s/^\s*#USE_PROXY_IP\s*// if $configuration::sip_host;
      $cfg_text .= $_;
  }

  # Save the configurations to temp files
  my $cfg_file = new File::Temp;
  my $sql_file = new File::Temp;
  print_to($cfg_file,$cfg_text);
  print_to($sql_file,$sql_text);

  # Move the temp files to their final destinations
  info("Installing new configuration");
  CCNQ::Install::_execute('sudo','cp',$cfg_file,runtime_opensips_cfg);
  CCNQ::Install::_execute('sudo','cp',$sql_file,runtime_opensips_sql);

  # Print out some info on how to use the SQL file.
  my $runtime_opensips_sql = runtime_opensips_sql;
  info(<<TXT);
Please run the following commands:
mysql <<SQL
  CREATE DATABASE ${configuration::db_name};
  CONNECT ${configuration::db_name};
  CREATE USER ${configuration::db_login} IDENTIFIED BY '${configuration::db_password}';
  GRANT ALL ON ${configuration::db_name}.* TO ${configuration::db_login};
SQL

mysql ${configuration::db_name} < ${runtime_opensips_sql}

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

    # Reconfigure the local system (includes installing the new opensips.cfg file in /etc/opensips)
    info("Reconfiguring the local system");
    eval { configure_opensips($model); };
    info($@) if $@;

    # Restart OpenSIPS using the new configuration.
    info("Restarting OpenSIPS");
    CCNQ::Install::_execute('sudo','/etc/init.d/opensips','restart');
  },
}
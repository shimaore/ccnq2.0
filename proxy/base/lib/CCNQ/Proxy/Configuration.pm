package CCNQ::Proxy::Configuration;

use Logger::Syslog;
use CCNQ::Install;
use CCNQ::Proxy;

use lib CCNQ::Proxy::proxy_base_lib;
use CCNQ::Proxy::Base;

=pod
  package configuration; # in /etc/ccn/configuration.pm
  # OpenSIPS parameters.
  our $sip_host       = '127.0.0.1'; # or blank for all local interfaces
  our $sip_port       = '5060';
  our $sip_challenge  = 'CarrierClass.net'; # or blank for: use domain
  our $opensips_cfg   = '/etc/opensips/opensips.cfg';
  our $mpath          = '/usr/lib/opensips/modules/';
  our $debug          = 3; # Debug level
  our $accounting     = 'flatstore'; # either '', 'flatstore' or 'radius'; currently flatstore is always enabled by default
  our $authenticate   = 'db'; # either 'db' or 'radius'
  our $radius_config  = '/etc/radiusclient/radiusclient.conf'; # Location of the Radius library config file
  our $mp_allowed     = 1; # Allow Media Proxy?
  our $mp_always      = 0; # Set to 1 to force media-proxy on all calls. Make sure you have enough media-proxy servers to handle the load, otherwise calls will be rejected or fail.
  our $node_id        = ''; # Either none (no node-specific routing) or one of the IPs listed in $sip_servers below.

  our $max_hops       = '10'; # Maximum number of hops before rejection (loop prevention)
  our $inv_timer      = 60;
  1;
=cut

# Use sensible defaults if no configuration.pm is found.
eval { require (CCNQ::Install::CCN.'/configuration.pm'); };
warning('(probably harmless) '.$@) if $@;

use constant accounting   => $configuration::accounting   || 'flatstore';
use constant authenticate => $configuration::authenticate || 'db';
use constant db_login     => $configuration::db_login     || 'opensips';
use constant db_password  => $configuration::db_password  || 'opensips';
use constant db_host      => $configuration::db_host      || '127.0.0.1';
use constant db_name      => $configuration::db_name      || 'opensips';
use constant node_id      => $configuration::node_id      || '';

use constant proxy_ip     => $configuration::sip_host       || '';
use constant proxy_port   => $configuration::sip_port       || '5060';
use constant challenge    => $configuration::sip_challenge  || '';

use constant opensips_uri => join('','mysql://',db_login,':',db_password,'@',db_host,'/'.db_name);
use constant dbd_uri      => join('','DBI:mysql:database=',db_name,';host=',db_host); # .';port='.$port

sub parameters {

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
    PROXY_IP    => proxy_ip,
    PROXY_PORT  => proxy_port,
    CHALLENGE   => challenge,
    DB_URL      => opensips_uri,
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
    NODE_ID     => node_id,
    INV_TIMER   => $configuration::inv_timer || 60,
  );

  return %values;
}

use AnyEvent::DBI;

sub ae_dbi_db {
  debug("Creating new ae_dbi_db for ".dbd_uri);
  return new AnyEvent::DBI dbd_uri, db_login, db_password,
    exec_server => 1,
    on_error => sub {
      my ($dbh,$filename,$line,$fatal) = @_;
      error("ae_dbi_db Error: ${filename}/${line}: $@");
    };
}

sub run_from_class {
  my ($class,$action,$params,$context) = @_;
  debug("run_from_class($class,$action)");
  $context->{ae_dbi_db}->{$class} ||= ae_dbi_db();
  my $db = $context->{ae_dbi_db}->{$class};
  my $challenge = challenge;
  eval qq{
    use lib proxy_base_lib;
    use CCNQ::Proxy::${class};
    my \$b = new CCNQ::Proxy::${class} (\$db,\$challenge);
    return \$b->run(\$action,\$params,\$context);
  };
  error($@) if $@;
  return undef;
}

1;
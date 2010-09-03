package CCNQ::Proxy::Configuration;

use Logger::Syslog;
use CCNQ::Install;
use CCNQ::Proxy;

use CCNQ::Proxy::Base;

# use constant accounting   => 'flatstore';
use constant accounting   => 'none';
use constant authenticate => 'db';
use constant db_login     => 'opensips';
use constant db_password  => 'opensips';
use constant db_host      => '127.0.0.1';
use constant db_name      => 'opensips';
use constant node_id      => '';

use constant proxy_ip     => '';
use constant::defer internal_ip => sub { CCNQ::Install::internal_ip || '' };
use constant::defer external_ip => sub { CCNQ::Install::external_ip || '' };
use constant proxy_port   => '5060';
use constant challenge    => '';

use constant opensips_uri => join('','mysql://',db_login,':',db_password,'@',db_host,'/'.db_name);
use constant dbd_uri      => join('','DBI:mysql:database=',db_name,';host=',db_host); # .';port='.$port

use constant cdr_directory => '/var/log/opensips';

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
    MPATH       => '/usr/lib/opensips/modules/',
    RADIUS_CONFIG => '',
    DEBUG       => 0,
    MP_ALLOWED  => 1,
    MP_ALWAYS   => 0,
    MAX_HOPS    => '10',
    # If multiple servers are chained it may be necessary to use different names for the VSF parameter.
    UAC_VSF     => 'vsf',
    NODE_ID     => node_id,
    INV_TIMER   => 90,
    FORCE_INTERNAL => internal_ip ? 'force_send_socket('.internal_ip.');' : '',
    FORCE_EXTERNAL => external_ip ? 'force_send_socket('.external_ip.');' : '',
  );

  return %values;
}

use AnyEvent::DBI;

sub ae_dbi_db {
  debug("Creating new ae_dbi_db for ".dbd_uri);
  return new AnyEvent::DBI dbd_uri, db_login, db_password,
    exec_server => 1;
}

sub run_from_class {
  my ($class,$action,$params,$context) = @_;
  debug("run_from_class($class,$action)");
  # $context->{ae_dbi_db}->{$class} ||= ae_dbi_db();
  # my $db = $context->{ae_dbi_db}->{$class};
  my $db = ae_dbi_db();
  my $challenge = challenge;
  my $r = undef;
  eval qq{
    use CCNQ::Proxy::${class};
    my \$b = new CCNQ::Proxy::${class} (\$db,\$challenge);
    \$r = \$b->run(\$action,\$params,\$context);
  };
  die $@ if $@;
  return $r if $r;
  die ['run_from_class([_1],[_2]): no condvar returned',$class,$action];
}

1;

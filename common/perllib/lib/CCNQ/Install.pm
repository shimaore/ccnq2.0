package CCNQ::Install;
# Copyright (C) 2009  Stephane Alnet
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 3
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
use strict; use warnings;
use Carp;
use File::Spec;
use Digest::SHA1 qw(sha1_hex);

use AnyEvent;
use AnyEvent::DNS;

use CCNQ::Util;
use Logger::Syslog;

use File::ShareDir;
use CCNQ;

# Where the local configuration information is kept.
use constant CCN => q(/etc/ccn);

=pod
  $text = get_variable($name,$file,$guess_tool)
    Loads variable $name from the environment, or from $file if it exists.
    Otherwise creates $file with the value guessed by $guess_tool,
    and exits.
=cut

use constant ENV_Prefix => 'CCNQ_';

sub get_variable {
  my ($what,$file,$guess_tool) = @_;

  # Used e.g. by the test tools.
  my $env_variable = ENV_Prefix().$what;
  if( exists($ENV{$env_variable}) && defined($ENV{$env_variable}) ) {
    my $result = $ENV{$env_variable};
    info("Using environment ${what} ${result}.");
    return $result;
  }

  if(-f $file) {
    my $result = CCNQ::Util::first_line_of($file);
    info("Using existing ${what} ${result}.");
    return $result;
  }

  my $guess = $guess_tool->();
  info("Found ${what} ${guess}, please edit ${file} if needed.");
  CCNQ::Util::print_to($file,$guess);
  return $guess;
}

=pod
  $filename = tag_to_file($tag)
    Returns the filename (under CCNQ::Install::CCN) where the $tag is
    stored.
    Generally used in conjunction with get_variables() to retrieve
    a configuration value for a specific tag.
=cut

sub tag_to_file {
  return File::Spec->catfile(CCN,shift);
}

# cookie resolution

use constant cookie_tag => 'cookie';
use constant cookie_file => tag_to_file(cookie_tag);

# Note: we die if we cannot find the cookie file, since without
#       it we won't be able to authenticate ourselves to the rest
#       of the system.

use constant::defer cookie => sub {
  get_variable(cookie_tag,cookie_file,sub{croak "No cookie file ".cookie_file." found"});
};

# Source path resolution

# Try to guess the source location from the value of $0.

use constant CCNQ_MAKEFILE_MODULE_NAME => 'CCNQ';
use constant SRC => File::ShareDir::dist_dir(CCNQ_MAKEFILE_MODULE_NAME);

# host_name and domain_name resolution
use Net::Domain;

use constant host_name_tag => 'host_name';
use constant domain_name_tag => 'domain_name';

use constant host_name_file => tag_to_file(host_name_tag);
use constant domain_name_file => tag_to_file(domain_name_tag);

use constant::defer host_name => sub {
  get_variable(host_name_tag,host_name_file,sub {Net::Domain::hostname()});
};
use constant::defer domain_name => sub {
  get_variable(domain_name_tag,domain_name_file,sub {Net::Domain::hostdomain()});
};

=pod
  $dns_name = catdns(@dns_fragments)
    Like File::Spec->catfile, but for DNS names.
=cut

sub catdns {
  return join('.',@_);
}

use constant::defer fqdn => sub { catdns(host_name,domain_name) };
sub cluster_fqdn {
  return catdns($_[0],domain_name);
}

# XXX This assumes default ejabberd mod_muc configuration and needs
#     to be documented / modified.
sub make_muc_jid {
  my $cluster_name = shift;
  return $cluster_name.'@conference.'.domain_name;
}

# XXX This assumes the "manager" cluster is called "manager".
use constant::defer manager_cluster_jid => sub { make_muc_jid('manager') };

use constant xmpp_tag => 'xmpp-agent';


sub make_password {
  return sha1_hex(join('',fqdn,cookie,@_));
}

# Service definitions

use constant roles_to_functions => {
  'carrier-sbc'     => [qw( b2bua/cdr b2bua/carrier_sbc_config b2bua/base monit node )],
  'client-sbc'      => [qw( b2bua/cdr b2bua/client_sbc_config  b2bua/base monit node )],
  'client-ocs-sbc'  => [qw( b2bua/cdr b2bua/client_ocs_sbc b2bua/base monit node )],
  'inbound-proxy'   => [qw( proxy/inbound_proxy proxy/base monit node )],
  'outbound-proxy'  => [qw( proxy/outbound_proxy proxy/base monit node )],
  'complete-transparent-proxy' => [qw( proxy/complete_transparent proxy/base mediaproxy/dispatcher mediaproxy monit node )],
  'router-no-registrar' => [qw( proxy/router_no_registrar proxy/base monit node )],
  # ...
  'api'             => [qw( node/api )],
  'provisioning'    => [qw( node/provisioning )],
  'realtime_estimator' => [qw( billing realtime_estimator)],
  'billing'         => [qw( billing )],
  'bucket_db'       => [qw( bucket_db )],
  'cdr'             => [qw( cdr )],
  'manager'         => [qw( manager monit node )],
  'aggregator'      => [qw( billing/aggregator node/api monit node )],
  # ...
  'mediaproxy-relay' => [qw( mediaproxy/relay mediaproxy monit node )],
};

# Service discovery

# Note: this is done using DNS.
#       A better choice would be to connect to the XMPP server ASAP
#       and gather that information as part of the regular startup
#       process.

use constant clusters_tag => 'clusters';
use constant roles_tag    => 'roles';

use constant _install_file => q(install.pm);

# Resolve cluster_name(s)

sub resolve_cluster_names {
  my $cv = AE::cv;
  AnyEvent::DNS::txt fqdn, $cv;
  my @cluster_names = $cv->recv;
  return join(' ',@cluster_names);
}

use constant clusters_file => tag_to_file(clusters_tag);

use constant::defer cluster_names => sub {
  [ split(' ',get_variable(clusters_tag,clusters_file,sub {resolve_cluster_names})) ];
};

# Resolve role(s) and function(s)

sub resolve_roles {
  my ($cluster_name) = @_;
  my $cv = AE::cv;
  AnyEvent::DNS::txt catdns($cluster_name,domain_name), $cv;
  my @roles = $cv->recv;
  return join(' ',@roles);
}

sub resolve_roles_and_functions {
  my $cb = shift;
  for my $cluster_name (@{cluster_names()}) {
    my @roles = resolve_roles($cluster_name);
    my %functions = ();
    for my $role (@roles) {
      for my $function (@{roles_to_functions()->{$role}}) {
        $cb->($cluster_name,$role,$function);
      }
    }
  }
}

use constant api_rendezvous_host => '127.0.0.1';
use constant api_rendezvous_port => 9090;

use constant realtime_estimator_rendezvous_host => '127.0.0.1';
use constant realtime_estimator_rendezvous_port => 7070;

use constant couchdb_local_server_tag => 'couchdb_local_server';
use constant couchdb_local_server_file => tag_to_file(couchdb_local_server_tag);
use constant::defer couchdb_local_server => sub {
  get_variable(couchdb_local_server_tag,couchdb_local_server_file,sub {'127.0.0.1'});
};


# Try to locate the "internal" and "external" IP addresses, if any are specified.

use constant internal_ip_tag => 'internal';
use constant external_ip_tag => 'external';

sub internal_ip {
  my $cv = AE::cv;
  AnyEvent::DNS::a catdns(internal_ip_tag,fqdn), $cv;
  my ($internal_ip) = $cv->recv;
  return $internal_ip;
}

sub external_ip {
  my $cv = AE::cv;
  AnyEvent::DNS::a catdns(external_ip_tag,fqdn), $cv;
  my ($external_ip) = $cv->recv;
  return $external_ip;
}

1;

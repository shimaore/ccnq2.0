#!/usr/bin/perl
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

# Note: install.pl is started from the proper directory, so locating
# CCNQ::Install is not an issue.

use CCNQ::Install;

# host_name and domain_name resolution

use constant host_name => 'host_name';
use constant domain_name => 'domain_name';

use constant host_name_file => File::Spec->catfile(CCNQ::Install::CCN,host_name);
use constant host_name_file => File::Spec->catfile(CCNQ::Install::CCN,domain_name);

use Net::Domain;

our $host_name =>
  get_variable(host_name,host_name_file,Net::Domain::hostname());
our $domain_name =>
  get_variable(domain_name,domain_name_file,Net::Domain::domainname());

sub catdns {
  return join('.',@_);
}

our $fdqn = catdns($host_name,$domain_name);

use AnyEvent::DNS;

# Service definitions

use constant roles_to_functions => {
  'carrier-sbc' => [qw( b2bua/base b2bua/cdr b2bua/carrier-sbc-config )],
  'client-sbc'  => [qw( b2bua/base b2bua/cdr b2bua/client-sbc-config )],
  'inbound-proxy' => [qw( proxy/inbound-proxy proxy/base )],
  'outbound-proxy' => [qw( proxy/outbound-proxy proxy/base )],
  'complete-transparent-proxy' => [qw( proxy/registrar proxy/mediaproxy proxy/complete-transparent proxy/base )],
  'router' => [qw( proxy/registrar proxy/router proxy/base )],
  # ...
};

# Service discovery

use constant _clusters => '_clusters';
use constant _roles    => '_roles';

use constant _install_file => q(install.pm);

# Resolve cluster_name(s)

my $cv = AnyEvent->condvar;
AnyEvent::DNS::txt catdns(_clusters,$fqdn), $cv;
my @cluster_names = $cv->recv;

# Resolve role(s) and function(s)

for my $cluster_name (@cluster_names) {
  my $cv = AnyEvent->condvar;
  AnyEvent::DNS::txt catdns(_roles,$cluster_name,$domain_name), $cv;
  my @roles = $cv->recv;

  for my $role (@roles) {
    for my $function (@{roles_to_function->{$role}}) {
      print "Installing function $function for role $role in cluster $cluster_name.\n";
      my $install_file = File::Spec->catfile(CCNQ::Install::SRC,$function,_install_file);
      my $eval = content_of($install_file);
      eval($eval);
      warn("In ${install_file}: $@") if $@;
    }
  }
}

print "Done.\n";

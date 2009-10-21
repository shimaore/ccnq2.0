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

use Logger::Syslog;

# Where the local configuration information is kept.
use constant CCN => q(/etc/ccn);


sub _execute {
  my $command = join(' ',@_);
  my $ret = system(@_);
  return 1 if $ret == 0;
  # Happily lifted from perlfunc.
  if ($? == -1) {
      print STDERR "Failed to execute ${command}: $!\n";
  }
  elsif ($? & 127) {
      printf STDERR "Child command ${command} died with signal %d, %s coredump\n",
          ($? & 127),  ($? & 128) ? 'with' : 'without';
  }
  else {
      printf STDERR "Child command ${command} exited with value %d\n", $? >> 8;
  }
  return 0;
}

sub first_line_of {
  open(my $fh, '<', $_[0]) or croak "$_[0]: $!";
  my $result = <$fh>;
  chomp($result);
  close($fh) or croak "$_[0]: $!";
  return $result;
}

sub content_of {
  open(my $fh, '<', $_[0]) or croak "$_[0]: $!";
  local $/;
  my $result = <$fh>;
  close($fh) or croak "$_[0]: $!";
  return $result;
}

sub print_to {
  open(my $fh, '>', $_[0]) or croak "$_[0]: $!";
  print $fh $_[1];
  close($fh) or croak "$_[0]: $!";
}

sub get_variable {
  my ($what,$file,$guess_tool) = @_;
  my $result;
  if(-e $file) {
    $result = first_line_of($file);
    print "Using existing $what $result .\n";
  } else {
    my $guess = $guess_tool();
    print "Found $what $guess, please edit $file if needed.\n";
    print_to($file,$guess);
    exit(1);
  }
  return $result;
}

sub tag_to_file {
  return File::Spec->catfile(CCNQ::Install::CCN,shift);
}

# cookie resolution

use constant cookie_tag => 'cookie';
use constant cookie_file => tag_to_file(cookie_tag);

# Note: we die if we cannot find the cookie file, since without
#       it we won't be able to authenticate ourselves to the rest
#       of the system.

use constant cookie =>
  get_variable(cookie_tag,cookie_file,sub{die "No cookie file ".cookie_file." found"});


# Source path resolution

# Try to guess the source location from the value of $0.
use contant container_path => sub {
  my $abs_path = File::Spec->rel2abs($0);
  my ($volume,$directories,$file) = File::Spec->splitpath($abs_path);
  my @directories = File::Spec->splitdir($directories);
  pop @directories; # Remove bin/
  pop @directories; # Remove common/
  $directories = File::Spec->catdir(@directories);
  return File::Spec->catpath($volume,$directories,'');
}->();

use constant source_path_tag => 'source_path';
use constant source_path_file => tag_to_file(source_path_tag);

use constant SRC => get_variable(source_path_tag,source_path_file,container_path);

use constant install_script_dir => File::Spec->catfile(SRC,'common','bin');

# host_name and domain_name resolution
use Net::Domain;

use constant host_name_tag => 'host_name';
use constant domain_name_tag => 'domain_name';

use constant host_name_file => tag_to_file(host_name_tag);
use constant host_name_file => tag_to_file(domain_name_tag);

use constant host_name =>
  get_variable(host_name_tag,host_name_file,sub {Net::Domain::hostname()});
use constant domain_name =>
  get_variable(domain_name_tag,domain_name_file,sub {Net::Domain::domainname()});

# Like File::Spec::catfile, but for DNS names.
sub catdns {
  return join('.',@_);
}

use constant fqdn => catdns($host_name,$domain_name);

use constant xmpp_tag => 'xmpp-agent';


sub make_password {
  return sha1_hex(join('',fqdn,cookie,@_);
}

# Service definitions

use constant roles_to_functions => {
  'carrier-sbc' => [qw( b2bua/base b2bua/cdr b2bua/carrier-sbc-config node )],
  'client-sbc'  => [qw( b2bua/base b2bua/cdr b2bua/client-sbc-config node )],
  'inbound-proxy' => [qw( proxy/inbound-proxy proxy/base node )],
  'outbound-proxy' => [qw( proxy/outbound-proxy proxy/base node )],
  'complete-transparent-proxy' => [qw( proxy/registrar proxy/mediaproxy proxy/complete-transparent proxy/base node )],
  'router' => [qw( proxy/registrar proxy/router proxy/base node )],
  # ...
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
  my $cv = AnyEvent->condvar;
  AnyEvent::DNS::txt $fqdn, $cv;
  my @cluster_names = $cv->recv;
  return join(' ',@cluster_names);
}

use constant clusters_file => tag_to_file(clusters_tag);

use constant cluster_names =>
  [ split(' ',get_variable(clusters_tag,clusters_file,sub {resolve_cluster_names})) ];

# Resolve role(s) and function(s)

sub resolve_roles {
  my ($cluster_name) = @_;
  my $cv = AnyEvent->condvar;
  AnyEvent::DNS::txt catdns($cluster_name,domain_name), $cv;
  my @roles = $cv->recv;
  return join(' ',@roles);
}

sub resolve_roles_and_functions {
  my $cb = shift;
  for my $cluster_name (@{cluster_names}) {
    my @roles = resolve_roles($cluster_name);
    my %functions = ();
    for my $role (@roles) {
      for my $function (@{roles_to_function->{$role}}) {
        $cb->($cluster_name,$role,$function);
      }
    }
  }
}

use constant actions_file_name => 'actions.pm';

sub attempt_run {
  my ($function,$action,$params) = @_;

  debug("Attempting ${action} in function ${function}.\n");
  my $run_file = File::Spec->catfile(CCNQ::Install::SRC,$function,actions_file_name);

  debug("No such file $run_file, skipping") unless -e $run_file;
  my $eval = content_of($run_file);

  # The script should return a hashref, which keys are the actions and
  # the values are sub().
  my $run = eval($eval);

  my $result = undef;
  eval {
    $result = $run->{$action}->($params) if $run->{$action};
  };
  warning("In ${run_file} ($cluster_name,$role,$function,$action): $@") if $@;
  return $result;
}

sub attempt_on_roles_and_functions {
  our $action = shift;
  our $params = shift || {};
  our ($action,$params) = @_;
  resolve_roles_and_functions(sub {
    our ($cluster_name,$role,$function) = @_;
    attempt_run($function,$action,{ %{$params}, cluster_name => $cluster_name, role => $role });
  });
}

use constant xmpp_restart_all => 'restart_all';

1;
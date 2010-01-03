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
use AnyEvent::Util;

use Logger::Syslog;

# Where the local configuration information is kept.
use constant CCN => q(/etc/ccn);

# Non-blocking version
sub _execute {
  my $context = shift;
  my $command = join(' ',@_);

  my $cv = AnyEvent::Util::run_cmd([@_]);

  $cv->cb( sub {
    my $ret = shift->recv;
    return 1 if $ret == 0;
    # Happily lifted from perlfunc.
    if ($ret == -1) {
        error("Failed to execute ${command}: $!");
    }
    elsif ($ret & 127) {
        error(sprintf "Child command ${command} died with signal %d, %s coredump",
            ($ret & 127),  ($ret & 128) ? 'with' : 'without');
    }
    else {
        info(sprintf "Child command ${command} exited with value %d", $ret >> 8);
    }
    return 0;
  });

  $context->{condvar}->cb($cv);
}

# Blocking version (used in "install" blocks)
sub execute {
  my $command = join(' ',@_);

  my $ret = system(@_);
  # Happily lifted from perlfunc.
  if ($ret == -1) {
      error("Failed to execute ${command}: $!");
  }
  elsif ($ret & 127) {
      error(sprintf "Child command ${command} died with signal %d, %s coredump",
          ($ret & 127),  ($ret & 128) ? 'with' : 'without');
  }
  else {
      info(sprintf "Child command ${command} exited with value %d", $ret >> 8);
  }
  return 0;
}

=pod
  $text = first_line_of($filename)
    Returns the first line of the file $filename,
    or undef if an error occurred.
=cut

sub first_line_of {
  open(my $fh, '<', $_[0]) or error("$_[0]: $!"), return undef;
  my $result = <$fh>;
  chomp($result);
  close($fh) or error("$_[0]: $!"), return undef;
  return $result;
}

=pod
  $content = content_of($filename)
    Returns the content of file $filename,
    or undef if an error occurred.
=cut

sub content_of {
  open(my $fh, '<', $_[0]) or error("$_[0]: $!"), return undef;
  local $/;
  my $result = <$fh>;
  close($fh) or error("$_[0]: $!"), return undef;
  return $result;
}

=pod
  print_to($filename,$content)
    Saves the $content to the specified $filename.
    croak()s on errors.
=cut

sub print_to {
  open(my $fh, '>', $_[0]) or croak "$_[0]: $!";
  print $fh $_[1];
  close($fh) or croak "$_[0]: $!";
}

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
    my $result = first_line_of($file);
    info("Using existing ${what} ${result}.");
    return $result;
  }

  my $guess = $guess_tool->();
  info("Found ${what} ${guess}, please edit ${file} if needed.");
  print_to($file,$guess);
  exit(1);
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

use constant source_path_tag => 'source_path';
use constant source_path_file => tag_to_file(source_path_tag);

use constant::defer SRC => sub { get_variable(source_path_tag,source_path_file,sub {
  # Work under the assumption that upgrade.pl already did the right thing.
  my $abs_path = File::Spec->rel2abs(File::Spec->curdir());
  # my $abs_path = File::Spec->rel2abs($0);
  my ($volume,$directories,$file) = File::Spec->splitpath($abs_path);
  my @directories = File::Spec->splitdir($directories);
  pop @directories; # Remove bin/
  pop @directories; # Remove common/
  $directories = File::Spec->catdir(@directories);
  return File::Spec->catpath($volume,$directories,'');
})};

use constant::defer install_script_dir => sub { File::Spec->catfile(SRC,'common','bin') };

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
  'carrier-sbc'     => [qw( b2bua/cdr b2bua/carrier-sbc-config b2bua/base monit node )],
  'client-sbc'      => [qw( b2bua/cdr b2bua/client-sbc-config  b2bua/base monit node )],
  'client-ocs-sbc'  => [qw( b2bua/cdr b2bua/client-ocs-sbc b2bua/base monit node )],
  'ocs-sbc'         => [qw( b2bua/cdr b2bua/ocs  b2bua/base monit node )],
  'inbound-proxy'   => [qw( proxy/inbound-proxy proxy/base monit node )],
  'outbound-proxy'  => [qw( proxy/outbound-proxy proxy/base monit node )],
  'complete-transparent-proxy' => [qw( proxy/registrar proxy/complete-transparent proxy/base mediaproxy/dispatcher mediaproxy monit node )],
  'router-no-registrar' => [qw( proxy/router-no-registrar proxy/base monit node )],
  # ...
  'portal'          => [qw( portal/base node/api monit node )],
  'api'             => [qw( node/api )],
  'provisioning'    => [qw( node/provisioning )],
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
  my $cv = AnyEvent->condvar;
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
  my $cv = AnyEvent->condvar;
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

use constant actions_file_name => 'actions.pm';

=pod

  attempt_run locates an "actions.pm" module and returns a sub() that
  will execute an action in it.
  "actions.pm" modules must return a hashred, which keys are the action
  names, and the values are sub()s.

  The sub($cv) returned by attempt_run expects one argument, an AnyEvent
  condvar, which will be sent the result, in the form:

  { status => 'completed', params => $results }
  { status => 'failed', error => $error_msg }

  Note: failure is detected by the presence of the "error" field,
        not by the fact that status is "failed".

=cut

use constant STATUS_COMPLETED => 'completed';
use constant STATUS_FAILED    => 'failed';

sub SUCCESS {
  my $result = shift;
  error(Carp::longmess("$result is not an hashref")) if $result && ref($result) ne 'HASH';
  return $result ? { status => STATUS_COMPLETED, params => $result, from => host_name }
                 : { status => STATUS_COMPLETED,                    from => host_name };
}

sub FAILURE {
  my $error = shift || 'No error specified';
  return { status => STATUS_FAILED, error => $error, from => host_name };
}

use constant CANCEL => {};

sub attempt_run {
  my ($function,$action,$params,$context) = @_;

  debug(qq(attempt_run($function,$action): started));
  my $run_file = File::Spec->catfile(SRC,$function,actions_file_name);

  # Errors which lead to not being able to submit the request are not reported.
  my $cancel = sub { debug("attempt_run($function,$action): cancel"); shift->send(CANCEL); };

  # No "actions.pm" for the selected function.
  warning(qq(attempt_run($function,$action): No such file "${run_file}", skipping)),
  return $cancel unless -e $run_file;

  # An error occurred while reading the file.
  my $eval = content_of($run_file);
  return $cancel if !defined($eval);

  # An error occurred while parsing the file.
  my $run = eval($eval);
  warning(qq(attempt_run($function,$action): Executing "${run_file}" returned: $@)),
  return $cancel if $@;

  return sub {
    my $cv = shift;
    debug("start of attempt_run($function,$action)->($cv)");

    my $result = undef;
    eval {
      if($run->{$action}) {
        $run->{$action}->($params,$context,$cv);
      } elsif($run->{_dispatch}) {
        $run->{_dispatch}->($action,$params,$context,$cv);
      } else {
        debug("attempt_run($function,$action): No action available");
        $cancel->($cv);
      }
      return;
    };

    if($@) {
      my $error_msg = "attempt_run($function,$action): failed with error $@";
      debug($error_msg);
      $cv->send(FAILURE($error_msg));
    }
    debug("end of attempt_run($function,$action)->($cv)");
  };
}

sub attempt_on_roles_and_functions {
  my ($action,$params,$context,$mcv) = @_;
  $params ||= {};

  resolve_roles_and_functions(sub {
    my ($cluster_name,$role,$function) = @_;
    my $fun = attempt_run($function,$action,{ %{$params}, cluster_name => $cluster_name, role => $role },$context);

    my $cv = AnyEvent->condvar;
    $fun->($cv);

    info("Waiting for Function: $function Action: $action Cluster: $cluster_name to complete");
    eval { $cv->recv };
    if($@) {
      error("Function: $function Action: $action Cluster: $cluster_name Failure: $@");
    } else {
      info("Function: $function Action: $action Cluster: $cluster_name Completed");
    }
  });
  $mcv->send;
}

use constant api_rendezvous_host => '127.0.0.1';
use constant api_rendezvous_port => 9090;

# Try to locate the "internal" and "external" IP addresses, if any are specified.

use constant internal_ip_tag => 'internal';
use constant external_ip_tag => 'external';

sub internal_ip {
  my $cv = AnyEvent->condvar;
  AnyEvent::DNS::a catdns(internal_ip_tag,fqdn), $cv;
  my ($internal_ip) = $cv->recv;
  return $internal_ip;
}

sub external_ip {
  my $cv = AnyEvent->condvar;
  AnyEvent::DNS::a catdns(external_ip_tag,fqdn), $cv;
  my ($external_ip) = $cv->recv;
  return $external_ip;
}

1;
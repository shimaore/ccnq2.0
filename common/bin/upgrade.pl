#!/usr/bin/perl
use strict; use warnings;

use Carp;

# Where the local configuration information is kept.
use constant CCN => q(/etc/ccn);

# Create the configuration directory.
use File::Path qw(mkpath);
die unless mkpath(CCN);

# This code should be in a separate module (CCNQ::Install)
# but cannot be since we don't even know where to find CCNQ::Install.

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
  my ($what,$file,$guess) = @_;
  my $result;
  if(-e $file) {
    $result = first_line_of($file);
    print "Using existing $what $result .\n";
  } else {
    print "Found $what $guess, please edit $file if needed.\n";
    print_to($file,$guess);
    exit(1);
  }
  return $result;
}

use File::Spec;

# Source path resolution

use constant source_path => 'source_path';

# SRC: where the copy of the original code lies.
# I create mine in ~/src using:
#    cd $HOME/src && git clone git://github.com/stephanealnet/ccnq2.0.git
# use constant HOME => $ENV{HOME};
# use constant SRC_DEFAULT => HOME.q(/src/ccnq2.0);

# Try to guess the source location from the value of $0.
sub container_path {
  my $abs_path = File::Spec->rel2abs($0);
  my ($volume,$directories,$file) = File::Spec->splitpath($abs_path);
  my @directories = File::Spec->splitdir($directories);
  pop @directories; # Remove bin/
  pop @directories; # Remove common/
  $directories = File::Spec->catdir(@directories);
  return File::Spec->catpath($volume,$directories,'');
}

use constant SRC_DEFAULT => container_path;

use constant _source_path_file => File::Spec->catfile(CCN,source_path);
use constant SRC => get_variable(source_path,_source_path_file,SRC_DEFAULT);

use constant _git_pull => [qw( git pull )];

chdir(SRC) or die "chdir(".SRC."): $!";
_execute(@{_git_pull});

# host_name and domain_name resolution

use constant host_name => 'host_name';
use constant domain_name => 'domain_name';

use constant host_name_file => File::Spec->catfile(CCN,host_name);
use constant host_name_file => File::Spec->catfile(CCN,domain_name);

use Net::Domain;

our $host_name =>
  get_variable(host_name,host_name_file,Net::Domain::hostname());
our $domain_name =>
  get_variable(domain_name,domain_name_file,Net::Domain::domainname());

sub catdns {
  return join('.',@_);
}

our $fdqn = catdns($host_name,$domain_name);


# Service discovery

use constant _clusters => '_clusters';
use constant _roles    => '_roles';

use constant roles_to_functions => {
  'carrier-sbc' => [qw( b2bua/base b2bua/cdr b2bua/carrier-sbc-config )],
  'client-sbc'  => [qw( b2bua/base b2bua/cdr b2bua/client-sbc-config )],
  'inbound-proxy' => [qw( proxy/inbound-proxy proxy/base )],
  'outbound-proxy' => [qw( proxy/outbound-proxy proxy/base )],
  'complete-transparent-proxy' => [qw( proxy/registrar proxy/mediaproxy proxy/complete-transparent proxy/base )],
  'router' => [qw( proxy/registrar proxy/router proxy/base )],
  # ...
};

use constant _install_file => q(install.pm);

use AnyEvent::DNS;

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
      my $install_file = File::Spec->catfile(SRC,$function,_install_file);
      my $eval = content_of($install_file);
      eval($eval);
      warn("In ${install_file}: $@") if $@;
    }
  }
}

print "Done.\n";

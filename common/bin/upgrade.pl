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

# Source path resolution

use File::Spec;

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

use constant install_script_dir => File::Spec->catfile(SRC,'common','bin');
use constant install_script => File::Spec->catfile(install_script_dir,'install.pl');

chdir(install_script_dir) or die "chdir(".install_script_dir."): $!";
exec install_script;

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
use File::Spec;

use Logger::Syslog;

# Where the local configuration information is kept.
use constant CCN => q(/etc/ccn);

sub run {
  # Create the configuration directory.
  use File::Path qw(mkpath);
  die "No ".CCN unless -d CCN or mkpath(CCN);

  # Source path resolution

  # Where does the copy of the original code lie?
  # I create mine in ~/src using:
  #    cd $HOME/src && git clone git://github.com/stephanealnet/ccnq2.0.git
  # therefor SRC_DEFAULT => $ENV{HOME}.q(/src/ccnq2.0);

  # Try to figure out where the current script is located.
  use constant script_path => sub {
    my $abs_path = File::Spec->rel2abs($0);
    my ($volume,$directories,$file) = File::Spec->splitpath($abs_path);
    my @directories = File::Spec->splitdir($directories);
    $directories = File::Spec->catdir(@directories);
    return File::Spec->catpath($volume,$directories,'');
  }->();

  chdir(script_path) or die "chdir(".script_path."): $!";
  debug("Starting from ".script_path."\n");
  eval q{
    use CCNQ::Install;
    use AnyEvent;

    my $program = AnyEvent->condvar;
    my $context = {
      condvar => $program,
    };
    # CCNQ::Install::attempt_run('node','upgrade',undef,$context)->();
    CCNQ::Install::attempt_run('node','install_all',undef,$context)->();
    $program->send->recv;
  };

  if($@) {
    error("upgrade.pl: $@");
  } else {
    info("upgrade.pl done.");
  }
}

run();

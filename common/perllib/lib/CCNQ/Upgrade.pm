package CCNQ::Upgrade;
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

use File::Path qw(mkpath);
use AnyEvent;

use CCNQ::Install;
use CCNQ::AE::Run;

sub run {
  # Create the configuration directory.
  die "No ".CCNQ::Install::CCN()
    unless -d CCNQ::Install::CCN()
        or mkpath(CCNQ::Install::CCN());

  # Keep the host and domain names, but re-resolve the list of clusters.
  unlink CCNQ::Install::clusters_file;

  # Make sure all variables are available:
  eval { CCNQ::Install::cookie()        };  my $warn1 = $@;
  eval { CCNQ::Install::fqdn()          };  my $warn2 = $@;
  eval { CCNQ::Install::cluster_names() };  my $warn3 = $@;

  die $warn1.$warn2.$warn3
    if $warn1 || $warn2 || $warn3;

  my $program = AnyEvent->condvar;
  my $context = {
    condvar => $program,
  };

  CCNQ::AE::Run::attempt_run('node','install_all',undef,$context)->($program);
  $program->recv;
}

'CCNQ::Upgrade';

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

use CCNQ;
use CCNQ::Install;
use CCNQ::AE::Run;

sub run {
  # Create the configuration directory.
  die "No ".CCNQ::CCN()
    unless -d CCNQ::CCN()
        or mkpath(CCNQ::CCN());

  # Keep the host and domain names, but re-resolve the list of clusters.
  unlink CCNQ::Install::clusters_file;

  # Make sure all variables are available:
  eval {
    CCNQ::Install::cookie();
    CCNQ::Install::fqdn();
    CCNQ::Install::cluster_names();
  };
  die $@ if $@;

  my $program = CCNQ::AE::Run::attempt_run('node','install_all',undef,undef)->();
  $program->recv();
}

'CCNQ::Upgrade';

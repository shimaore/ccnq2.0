package CCNQ::Actions::monit;
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

use CCNQ::Install;
use CCNQ::Util;
use File::Spec;

use CCNQ::Monit;

use Logger::Syslog;

sub _install {
  my ($params,$context) = @_;
  for my $file qw( monitrc conf.d/local conf.d/root-fs conf.d/cron
                    conf.d/ntp conf.d/named conf.d/ssh
                    conf.d/couchdb conf.d/freeswitch conf.d/opensips ) {
    my $src = File::Spec->catfile(CCNQ::Monit::monit_directory,$file);
    my $content = CCNQ::Util::content_of($src);
    $content =~ s/__HOST__/CCNQ::Install::host_name()/ge;
    $content =~ s/__DOMAIN__/CCNQ::Install::domain_name()/ge;
    my $dst = File::Spec->catfile(CCNQ::Monit::monit_target,$file);
    CCNQ::Util::print_to($dst,$content);
  }

  # Restart monit with the new configuration
  CCNQ::Util::execute('/etc/init.d/monit','restart');

  return;
}

'CCNQ::Actions::monit';

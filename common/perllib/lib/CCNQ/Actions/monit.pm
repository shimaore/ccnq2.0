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
  my @components = qw(
    monitrc conf.d/local conf.d/root-fs conf.d/cron
    conf.d/ntp conf.d/named conf.d/ssh
  );
  # XXX Replace by a system where the different components request
  #     monit modules.
  -e '/etc/init.d/couchdb' && -e '/usr/bin/couchdb'
    and push @components, qw( conf.d/couchdb );
  -e '/etc/init.d/freeswitch' && -e '/opt/freeswitch/bin/freeswitch'
    and push @components, qw( conf.d/freeswitch );
  -e '/etc/init.d/opensips' && -e '/usr/sbin/opensips'
    and push @components, qw( conf.d/opensips );

  for my $file (@components) {
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

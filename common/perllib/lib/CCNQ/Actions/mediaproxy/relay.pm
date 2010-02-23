package CCNQ::Actions::mediaproxy::relay;
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

use CCNQ::Util;
use CCNQ::AE;

use Logger::Syslog;

sub install {
  my ($params,$context,$mcv) = @_;
  use CCNQ::MediaProxy;
  CCNQ::MediaProxy::install_default_key('relay');

  my $cluster_fqdn = CCNQ::Install::cluster_fqdn($params->{cluster_name});

  my $config = <<"EOT";
# start relay configuration

[Relay]
dispatchers = ${cluster_fqdn}
passport = None
;relay_ip = <default host IP>
port_range = 40000:41998
;log_level = DEBUG
;stream_timeout = 90
;on_hold_timeout = 7200
;dns_check_interval = 60
;reconnect_delay = 10
;traffic_sampling_period = 15

# end relay configuration
EOT
  CCNQ::Util::print_to(CCNQ::MediaProxy::mediaproxy_config.'.relay',$config);
  $mcv->send(CCNQ::AE::SUCCESS);
}

'CCNQ::Actions::mediaproxy::relay';

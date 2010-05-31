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
use AnyEvent::DNS;

use Logger::Syslog;

sub _install {
  my ($params,$context) = @_;
  use CCNQ::MediaProxy;
  CCNQ::MediaProxy::install_default_key('relay');

  my $dns_txt = sub {
    my $dn = CCNQ::Install::catdns(@_);
    my $cv = AE::cv;
    AnyEvent::DNS::txt( $dn, $cv );
    return ($cv->recv);
  };

  $context->{resolver} = AnyEvent::DNS::resolver;

  my $cluster_fqdn = CCNQ::Install::cluster_fqdn($params->{cluster_name});

  my @dispatcher_names = $dns_txt->( 'dispatcher', $cluster_fqdn );
  debug("Query TXT dispatcher -> ".join(',',@dispatcher_names));

  my $dispatcher_names = join ' ', @dispatcher_names;

  my $config = <<"EOT";
# start relay configuration

[Relay]
dispatchers = ${dispatcher_names}
passport = None
;relay_ip = <default host IP>
port_range = 40000:41998
;log_level = DEBUG
; stream_timeout should be higher than INV_TIMER (I assume)
stream_timeout = 100
;on_hold_timeout = 7200
;dns_check_interval = 60
;reconnect_delay = 10
;traffic_sampling_period = 15

# end relay configuration
EOT
  CCNQ::Util::print_to(CCNQ::MediaProxy::mediaproxy_config.'.relay',$config);
  return;
}

'CCNQ::Actions::mediaproxy::relay';

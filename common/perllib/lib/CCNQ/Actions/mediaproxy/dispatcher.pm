package CCNQ::Actions::mediaproxy::dispatcher;
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

use Logger::Syslog;

sub _install {
  my ($params,$context) = @_;

  use CCNQ::MediaProxy;
  CCNQ::MediaProxy::install_default_key('dispatcher');
  my $config = <<'EOT';
# start dispatcher configuration

[Dispatcher]
socket_path = /var/run/mediaproxy/dispatcher.sock
;listen = 0.0.0.0
;listen_management = 0.0.0.0
;management_use_tls = yes
passport = None
;management_passport = None
;log_level = DEBUG
;relay_timeout = 5
;accounting =

[OpenSIPS]
;socket_path = /var/run/opensips/socket
;max_connections = 10

# end dispatcher configuration
EOT
  CCNQ::Util::print_to(CCNQ::MediaProxy::mediaproxy_config.'.dispatcher',$config);
  return;
}

'CCNQ::Actions::mediaproxy::dispatcher';

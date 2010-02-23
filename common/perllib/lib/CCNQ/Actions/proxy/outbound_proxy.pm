package CCNQ::Actions::proxy::outbound_proxy;
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
use Logger::Syslog;

use CCNQ::Proxy;
use CCNQ::Util;
use CCNQ::AE;

sub install {
  my ($params,$context,$mcv) = @_;

  CCNQ::Util::print_to(CCNQ::Proxy::proxy_mode_file,'outbound-proxy');
  $mcv->send(CCNQ::AE::SUCCESS);
}

'CCNQ::Actions::proxy::outbound_proxy';

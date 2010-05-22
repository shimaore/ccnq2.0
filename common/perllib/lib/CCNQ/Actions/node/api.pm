package CCNQ::Actions::node::api;
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

use CCNQ::API::Server;

sub _request {
  # Silently ignore. (These come to us because we are subscribed to the manager MUC.)
  return;
}

sub _session_ready { CCNQ::API::Server::_session_ready(@_) }

sub _response      { CCNQ::API::Server::_response(@_) }

'CCNQ::Actions::node::api';

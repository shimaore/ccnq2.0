package CCNQ::Actions::billing;
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

use Logger::Syslog;

use CCNQ::Billing;

sub _install {
  my ($params,$context) = @_;
  return;
}

sub billing_entry {
  my ($params,$context) = @_;

  # Create a new CBEF entry
  return CCNQ::Billing::rate_and_save_cbef({
    %{$params},
    collecting_node => CCNQ::Install::host_name,
    request_uuid    => $params->{activity},
  });
}

'CCNQ::Actions::billing';

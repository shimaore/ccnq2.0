package CCNQ::Actions::node;
# Copyright (C) 2009  Stephane Alnet
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation; either version 3
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
use strict; use warnings;

use Carp;
use AnyEvent;
use CCNQ::AE::Run;
use Logger::Syslog;

sub install_all {
    my ($params,$context) = @_;
    return CCNQ::AE::Run::attempt_on_roles_and_functions('_install',$params,$context);
}

sub restart_all {
    my ($params,$context) = @_;
    return CCNQ::AE::Run::attempt_on_roles_and_functions('_restart',$params,$context);
}

# Used to provide server-wide status information.
sub status {
  my ($params,$context) = @_;
  my $rcv = AE::cv;
  $rcv->send({running => 1});
  return $rcv;
}

sub restart_agent {
  my ($params,$context) = @_;
  use AnyEvent::Watchdog::Util;
  AnyEvent::Watchdog::Util::enabled
    or croak "Not running under watchdog!";
  AnyEvent::Watchdog::Util::restart;
  return;
}

'CCNQ::Actions::node';

package CCNQ::Actions::node;
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

use Carp;
use CCNQ::AE;
use CCNQ::AE::Run;
use CCNQ::Trace;

sub install_all {
    my ($params,$context,$mcv) = @_;
    CCNQ::AE::Run::attempt_on_roles_and_functions('install',$params,$context,$mcv);
}

# Used to provide server-wide status information.
sub status {
  my ($params,$context,$mcv) = @_;
  $mcv->send(CCNQ::AE::SUCCESS({running => 1}));
}

sub restart_all {
  my ($params,$context,$mcv) = @_;
  use AnyEvent::Watchdog::Util;
  AnyEvent::Watchdog::Util::enabled
    or croak "Not running under watchdog!";
  AnyEvent::Watchdog::Util::restart;
  $mcv->send(CCNQ::AE::SUCCESS);
}

'CCNQ::Actions::node';

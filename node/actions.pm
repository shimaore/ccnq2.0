# node/actions.pm

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

use Carp;

{
  install_all => sub {
    my ($params,$context,$mcv) = @_;
    CCNQ::Install::attempt_on_roles_and_functions('install',$params,$context);
    $mcv->send(CCNQ::Install::SUCCESS);
  },

  # Used to provide server-wide status information.
  status => sub {
    my ($params,$context,$mcv) = @_;
    $mcv->send(CCNQ::Install::SUCCESS({running => 1}));
  },

  restart_all => sub {
    my ($params,$context,$mcv) = @_;
    use AnyEvent::Watchdog::Util;
    AnyEvent::Watchdog::Util::enabled
      or croak "Not running under watchdog!";
    AnyEvent::Watchdog::Util::restart;
    $mcv->send(CCNQ::Install::SUCCESS);
  },

}
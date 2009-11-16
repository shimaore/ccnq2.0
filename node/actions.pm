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

{
  install_all => sub {
    my ($params,$context) = @_;
    CCNQ::Install::attempt_on_roles_and_functions('install',$params,$context);
    return { ok => 1 };
  },

  # Used to provide server-wide status information.
  status => sub {
    return {
      running => 1,
    };
  },

  restart_all => sub {
    use AnyEvent::Watchdog::Util;
    AnyEvent::Watchdog::Util::enabled
      or croak "Not running under watchdog!";
    AnyEvent::Watchdog::Util::restart;
    return { ok => 1 };
  },

}
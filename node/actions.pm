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
    CCNQ::Install::attempt_on_roles_and_functions('install');
    return { ok => 1 };
  },

  upgrade => sub {
    # Update the code from the Git repository.
    chdir(CCNQ::Install::SRC) or die "chdir(".CCNQ::Install::SRC."): $!";
    CCNQ::Install::_execute(qw( git pull ));
    # Switch back to the directory we normally run from.
    chdir(CCNQ::Install::install_script_dir) or die "chdir(".CCNQ::Install::install_script_dir."): $!";
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

  _session_ready => sub {
    my ($context) = @_;
    for my $muc_room (@{CCNQ::Install::cluster_names}) {
      info("Attempting to join $muc_room");
      $context->{muc}->join_room($con,$muc_room);
    }
    return { ok => 1 };
  }
}
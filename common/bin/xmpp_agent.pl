#!/usr/bin/perl
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

use AnyEvent::Watchdog autorestart => 1, heartbeat => 30;

use CCNQ::Install;
use CCNQ::XMPPAgent;

use Logger::Syslog;

use constant seconds_before_restarting => 2;

# This start all the proper agents
# Note: this might not be the best (proper) way to do it, since some
#       agents may need to be running as specific userids (for e.g. opensips or freeswitch).

sub run {
  info("xmpp_agent.pl starting");
  # Loop until we are asked to restart ourselves (e.g. after upgrade)
  # or until something breaks (e.g. server died).
  my $j = AnyEvent->condvar;

  CCNQ::Install::resolve_roles_and_functions(sub{
    my ($cluster_name,$role,$function) = @_;
    eval { CCNQ::XMPPAgent::start($function,$j); };
    error($@) if $@;
  });

  $j->recv;
  undef $j;

  sleep(seconds_before_restarting);
  run();
}
run();

#!/bin/sh
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

# This is a script I use in order to automatically restart the XMPP Agent
# on all servers.

# ~/bin/list.sh should 
#    export SERVERS="server1 server2 ..."
# with all servers.

source ~/bin/list.sh

# I assume you use ssh-agent and sudo NOPASSWD.
# I also assume you installed the source in ~/src/ccnq2.0 as mentioned
# in INSTALL.

for s in $SERVERS; do
  echo "Server $s"
  ssh $s 'cd src/ccnq2.0/common/bin || exit; killall xmpp_agent.pl; rm -f nohup.out; (nohup ./xmpp_agent.pl </dev/null >/dev/null 2>/dev/null &)' || echo 'Failed'
done

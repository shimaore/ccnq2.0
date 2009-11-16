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

# This is a script I use in order to automatically update the configuration
# on my servers at once.
# It takes one option, '-q', which should be used when only the proxy
# code has changed.

# ~/bin/list.sh should 
#    export SERVERS="server1 server2 ..."
# with all servers.

source ~/bin/list.sh

# I assume you use ssh-agent and sudo NOPASSWD.
# I also assume you installed the source in ~/src/ccnq2.0 as mentioned
# in INSTALL.

if [ "x$1" != "x-q" ]; then
for s in $SERVERS; do
  echo "Server $s"
  ssh $s 'cd /opt/freeswitch && sudo mv conf conf.`date "+%FT%T"`'
done
fi

for s in $SERVERS; do
  echo "Server $s"
  ssh $s 'cd src/ccnq2.0 && git pull' || echo 'Failed'
done

for s in $SERVERS; do
  echo "Server $s"
  ssh $s 'cd src/ccnq2.0/common/bin && sudo ./upgrade.pl && sudo tail -100 /var/log/syslog | grep -i error'
done

if [ "x$1" != "x-q" ]; then
for s in $SERVERS; do
  echo "Server $s"
  ssh $s 'cd /etc && sudo git add . && sudo git commit -a -m "Update"'
done

exec ~/bin/xmpp-restart-all.sh
fi

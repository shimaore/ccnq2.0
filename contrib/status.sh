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


# This script will show some status information about all your nodes
# (assuming you created the script "list.sh" as indicated), and
# reset log levels to their bare minimum.
# This might become a monit script.

# ~/bin/list.sh should 
#    export SERVERS="server1 server2 ..."
# with all servers.

source ~/bin/list.sh

SSH_OPTIONS=""

for s in $SERVERS; do
  echo "Server $s"
  echo Check disk space
  ssh $SSH_OPTIONS $s 'sudo rm /var/log/user.log* /var/log/messages* /var/log/debug*; df -k /'
  echo Check NTP sync
  ssh $SSH_OPTIONS $s 'echo pe | /usr/bin/ntpdc -n'
  echo Check DNS servers
  ssh $SSH_OPTIONS $s 'cat /etc/resolv.conf'
  echo OpenSIPS log level
  ssh $SSH_OPTIONS $s '/usr/sbin/opensipsctl fifo debug'
  ssh $SSH_OPTIONS $s '/usr/sbin/opensipsctl fifo debug 3'
  echo FreeSwitch log levels
  ssh $SSH_OPTIONS $s '/opt/freeswitch/bin/fs_cli -p CCNQ -x "console loglevel"'
  ssh $SSH_OPTIONS $s '/opt/freeswitch/bin/fs_cli -p CCNQ -x "console loglevel 0"'
  ssh $SSH_OPTIONS $s '/opt/freeswitch/bin/fs_cli -p CCNQ -x "fsctl loglevel"'
  ssh $SSH_OPTIONS $s '/opt/freeswitch/bin/fs_cli -p CCNQ -x "fsctl loglevel 1"'
done

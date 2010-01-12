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

# This script can be ran at startup time (e.g. from /etc/rc.local)
# to do real-time capture of SIP packets.
# It must be ran as root (which will happen if ran from /etc/rc.local).

# Which interface should we attempt to capture?
INTERFACES="eth0 eth1"
# Size of the capture spool / ring (in Mo)
SIZE_MB=100
# What should we capture?
FILTER='udp or icmp or tcp port 5060'

mkdir -p /var/run/traces
mkdir -p /var/log/traces

for intf in $INTERFACES;
do
  # Capture 1Mo per file, up to the indicated size
  /usr/bin/dumpcap \
    -p -i $intf \
    -a filesize:1024  -b files:$SIZE_MB \
    -w /var/log/traces/$intf.pcap \
    -f "${FILTER}" &
  # Save the PID
  echo $! > /var/run/traces/traces-$intf.pid
done


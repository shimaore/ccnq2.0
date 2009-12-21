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

#
# Usage: trace.sh
#   Gathers UDP sniffer traces for around 120s then merges them.
#   Outputs is placed in /tmp/trace.pcap.gz
#

source ~/bin/list.sh

INTERFACES="eth0 eth1"

# For each SIP server...
for s in $SIP_SERVERS; do
  echo "Starting trace for $s"

  # ...and each interface:
  for interface in $INTERFACES; do

    # Generate a temporary script file on the target server.
    echo '#/bin/sh' | \
       ssh -p 10022 $s "sudo tee /tmp/trace-${interface}.sh"
    echo "nohup /usr/bin/tshark -w /tmp/trace-${interface}.pcap -i ${interface} -a duration:120 'udp' >/tmp/trace-${interface}.log 2>&1 </dev/null &" | \
       ssh -p 10022 $s "sudo tee -a /tmp/trace-${interface}.sh"
    # Make it executable and run it
    ssh -p 10022 $s "sudo chmod +x /tmp/trace-${interface}.sh"
    ssh -p 10022 $s "sudo /tmp/trace-${interface}.sh"

  done

  # Confirm the captures are running
  ssh -p 10022 $s 'ps ax | grep tshark | grep -v grep'

done

echo "Waiting 120s"
sleep 120

rm -f /tmp/trace-*.pcap
for s in $SIP_SERVERS; do
  echo "Gathering data from $s"
  for interface in eth0 eth1; do
    scp -P 10022 "$s:/tmp/trace-${interface}.pcap" "/tmp/trace-${interface}-$s.pcap"
  done
done

echo "Merging trace files"
mergecap -w /tmp/trace.pcap /tmp/trace-*.pcap
gzip /tmp/trace.pcap

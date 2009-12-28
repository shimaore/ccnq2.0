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

# We assume you are running the contrib/traces.sh script
# This script will locate records that pertain to a specific to / from
# combination and return a report.

# NOTE: Might need to add the "-a" option to mergecap if we run into performance issues.

# Step 1: high-level filtering
mergecap -w - /var/log/traces/*.pcap | ngrep -i -l -q -I - -O "$1" "$2" >/dev/null;

# Step 2: low-level filtering and output
tshark -r "$1" -R "$3" -nltad $4

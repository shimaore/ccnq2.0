#!/bin/sh
# Copyright (C) 2006, 2009  Stephane Alnet
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

#
# For more information visit http://carrierclass.net/
#

# This script is called remotely via ssh. It should not be ran manually.
# This script is called remotely by rotate.pl.

TODAY=`/bin/date -u '+%Y%m%d-%H%M'`
DIR="/var/log/opensips/$TODAY"

mkdir -p "${DIR}"
mv /var/log/opensips/acc_*.log /var/log/opensips/missed_calls_*.log "${DIR}/"
/usr/sbin/opensipsctl fifo flat_rotate
# Note: with FIFO we have to wait for a new CDR to be written before we can safely
# assume the files have been closed and re-opened.

# Output the name of the directory where the log files were copied.
echo -n "${DIR}"

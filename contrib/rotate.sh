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

# This script will rotate log (CDR) files. Can be used e.g. from crontab.

# Timestamp in YYYY-MM-DD-HH-MM-SS format
TODAY=`/bin/date -u '+%Y-%m-%d-%H-%M-%S'`

# Rotate OpenSIPS
if [ -x /usr/sbin/opensipsctl ]; then  
  OPENSIPS_DIR="/var/log/opensips/$TODAY"
  mkdir -p "${OPENSIPS_DIR}"
  mv /var/log/opensips/acc_*.log /var/log/opensips/missed_calls_*.log "${OPENSIPS_DIR}/"
  /usr/sbin/opensipsctl fifo flat_rotate
fi

# Rotate FreeSwitch
if [ -x /opt/freeswitch/bin/fs_cli ]; then
  /opt/freeswitch/bin/fs_cli -p CCNQ -x 'fsctl send_sighup'
fi

package CCNQ::Proxy;
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

use CCNQ::Install;
use File::Temp;

use constant runtime_opensips_cfg => '/etc/opensips/opensips.cfg';
use constant runtime_opensips_sql => '/etc/opensips/opensips.sql';

use constant proxy_base_lib => File::Spec->catfile(CCNQ::Install::SRC,qw( proxy base lib ));
use constant opensips_base_lib => File::Spec->catfile(CCNQ::Install::SRC,qw( proxy base opensips));

1;
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

use constant::defer opensips_base_lib => sub { File::Spec->catfile(CCNQ::Install::SRC,qw( proxy base opensips)) };

use constant proxy_mode => 'proxy_mode';
use constant proxy_mode_file => File::Spec->catfile(CCNQ::Install::CCN,proxy_mode);

1;
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

use CCNQ::B2BUA;

{
  install => sub {
    my $b2bua_name = 'client-sbc-config';

    # acls
    for my $name ($b2bua_name) {
      CCNQ::B2BUA::copy_file($b2bua_name,qw( autoload_configs ),"${name}.acl.xml");
    }

    # dialplan
    for my $name ($b2bua_name) {
      CCNQ::B2BUA::copy_file($b2bua_name,qw( dialplan ),"${name}.xml");
    }

    # dialplan/template
    for my $name (qw( client-sbc-template ),
        map {($_.'-ingress',$_.'-egress')} qw( e164 france loopback transparent usa-cnam usa )) {
      CCNQ::B2BUA::copy_file($b2bua_name,qw( dialplan template ),"${name}.xml");
    }

    # sip_profile
    for my $name ($b2bua_name) {
      CCNQ::B2BUA::copy_file($b2bua_name,qw( sip_profiles ),"${name}.xml");
    }

    # scripts
    for my $name (qw( cnam.pl )) {
      CCNQ::B2BUA::copy_file($b2bua_name,qw( .. scripts ),${name});
    }

    return;
  },
}
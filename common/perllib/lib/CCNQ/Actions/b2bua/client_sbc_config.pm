package CCNQ::Actions::b2bua::client_sbc_config;
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
use strict; use warnings;

use CCNQ::B2BUA;
use CCNQ::AE;

use Logger::Syslog;

sub install {
  my ($params,$context,$mcv) = @_;

  my $b2bua_name = 'client-sbc-config';
  my $cluster_fqdn = CCNQ::Install::cluster_fqdn($params->{cluster_name});


  # acls
  for my $name ($b2bua_name) {
    CCNQ::B2BUA::copy_file($b2bua_name,qw( autoload_configs ),"${name}.acl.xml");
  }

  # dialplan
  my $dialplan_text = <<"EOT";
<!-- client-sbc-config -->
<X-PRE-PROCESS cmd="set" data="ingress_target=ingress-proxy.${cluster_fqdn}"/>
<X-PRE-PROCESS cmd="set" data="egress_target=egress-proxy.${cluster_fqdn}"/>

<X-PRE-PROCESS cmd="set" data="profile_name=usa"/>
<X-PRE-PROCESS cmd="include" data="template/client-sbc-template.xml"/>

<X-PRE-PROCESS cmd="set" data="profile_name=usa-cnam"/>
<X-PRE-PROCESS cmd="include" data="template/client-sbc-template.xml"/>

<X-PRE-PROCESS cmd="set" data="profile_name=france"/>
<X-PRE-PROCESS cmd="include" data="template/client-sbc-template.xml"/>

<X-PRE-PROCESS cmd="set" data="profile_name=e164"/>
<X-PRE-PROCESS cmd="include" data="template/client-sbc-template.xml"/>

<X-PRE-PROCESS cmd="set" data="profile_name=loopback"/>
<X-PRE-PROCESS cmd="include" data="template/client-sbc-template.xml"/>

<X-PRE-PROCESS cmd="set" data="profile_name=usa-cnam-bb"/>
<X-PRE-PROCESS cmd="include" data="template/client-sbc-template.xml"/>
EOT
  my $dialplan_file = CCNQ::B2BUA::install_dir(qw( dialplan ), "${b2bua_name}.xml" );
  CCNQ::Util::print_to($dialplan_file,$dialplan_text);

  # dialplan/template
  for my $name (qw( client-sbc-template ),
      map {($_.'-ingress',$_.'-egress')} qw( e164 france loopback transparent usa-cnam usa usa-cnam-bb )) {
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

  $mcv->send(CCNQ::AE::SUCCESS);
}

'CCNQ::Actions::b2bua::client_sbc_config';

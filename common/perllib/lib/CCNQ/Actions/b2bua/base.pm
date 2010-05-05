package CCNQ::Actions::b2bua::base;
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
use CCNQ::Util;
use Logger::Syslog;

use constant vars_xml => 'vars.xml';

sub _install {
  my ($params,$context) = @_;

  my $b2bua_name = 'base';

  CCNQ::B2BUA::install_file($b2bua_name,vars_xml, sub {
    my $txt = shift;
    my $host_fqdn    = CCNQ::Install::fqdn;
    my $domain_name  = CCNQ::Install::domain_name;
    return <<EOT . $txt;
      <X-PRE-PROCESS cmd="set" data="host_name=${host_fqdn}"/>
      <X-PRE-PROCESS cmd="set" data="domain_name=${domain_name}"/>
EOT
  });

  # freeswitch.xml
  CCNQ::B2BUA::copy_file($b2bua_name,'freeswitch.xml');

  # autoload_configs
  for my $name (qw(
    acl                    logfile
    cdr_csv                modules
    console                post_load_modules
    event_socket           sofia
    fifo                   switch
    local_stream           timezones
  )) {
    CCNQ::B2BUA::copy_file($b2bua_name,qw( autoload_configs ),"${name}.conf.xml");
  }

  # dialplan/template
  for my $name (qw( )) {
    CCNQ::B2BUA::copy_file($b2bua_name,qw( dialplan template ),"${name}.xml");
  }

  # sip_profile/template
  for my $name (qw( sbc-media sbc-nomedia )) {
    CCNQ::B2BUA::copy_file($b2bua_name,qw( sip_profiles template ),"${name}.xml");
  }

  CCNQ::B2BUA::finish();

  # Restart FreeSwitch using the new configuration.
  info("Restarting FreeSwitch");
  CCNQ::Util::execute('/bin/sed','-i','-e','s/^FREESWITCH_ENABLED="false"$/FREESWITCH_ENABLED="true"/','/etc/default/freeswitch');
  CCNQ::Util::execute('/etc/init.d/freeswitch','stop');
  CCNQ::Util::execute('/etc/init.d/freeswitch','start');

  CCNQ::Trace::install();
  return;
}

sub _session_ready {
  my ($params,$context) = @_;
  use CCNQ::XMPPAgent;
  CCNQ::XMPPAgent::join_cluster_room($context);
  return;
}

sub trace {
  use CCNQ::Trace;
  return CCNQ::Trace::run(shift->{params});
}

'CCNQ::Actions::b2bua::base';

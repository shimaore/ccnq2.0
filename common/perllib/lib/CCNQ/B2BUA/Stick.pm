package CCNQ::B2BUA::Stick;
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

=head1 NAME
  CCNQ::B2BUA::Stick
  Provides generic configuration for a server "on a stick".
  (Single IP, single port.)

=head1 TODO
  Assumes a single instance is available for each profile.
=cut

use CCNQ::B2BUA;
use CCNQ::Install;
use CCNQ::Util;
use CCNQ::AE;
use AnyEvent::DNS;
use File::Spec;

sub install {
    my ($b2bua_name,$params,$context,$mcv) = @_;
    use Logger::Syslog;

    debug("b2bua/$b2bua_name: Installing dialplan/template");
    for my $name ($b2bua_name) {
      CCNQ::B2BUA::copy_file($b2bua_name,qw( dialplan template ),"${name}.xml");
    }

    CCNQ::B2BUA::mk_dir(qw(autoload_configs));
    CCNQ::B2BUA::mk_dir(qw(sip_profiles));
    CCNQ::B2BUA::mk_dir(qw(dialplan));

    $context->{resolver} = AnyEvent::DNS::resolver;

    my $sip_profile_text = '';
    my $dialplan_text    = '';
    my $acl_text         = '';

    my $internal_ip = CCNQ::Install::internal_ip;

    for my $name ($b2bua_name) {
      # Figure out whether we have all the data to configure this instance.
      # We need to have at least:
      #   port      -- TXT record of the SIP port to use
      #   internal  -- A record of (host's) internal SIP IP
      # and zero or more of:
      #   ingress    -- A records with the IP address of the host allowed to send us SIP traffic.
      #   egress     -- A records with the IP address of the target for outbound traffic.

      my $profile = $name;

      my $extra = '';
      my $profile_template = 'public';
      my $dialplan_template = $profile;

      debug("b2bua/carrier-sbc-config: Creating configuration for name $name / profile $profile.");

      my $port_dn = CCNQ::Install::catdns('port',$name,CCNQ::Install::fqdn);
      my $port_cv = AnyEvent->condvar;
      AnyEvent::DNS::txt( $port_dn, $port_cv );
      my ($port) = $port_cv->recv;
      debug("Query TXT $port_dn -> $port") if defined $port;

      next unless defined($port) && defined($internal_ip);

      debug("b2bua/carrier-sbc-config: Found port $port");

      # Generate sip_profile entries
      $sip_profile_text .= <<"EOT";
        <X-PRE-PROCESS cmd="set" data="profile_name=${name}"/>
        <X-PRE-PROCESS cmd="set" data="sip_port=${port}"/>
        <X-PRE-PROCESS cmd="set" data="sip_ip=${internal_ip}"/>
        ${extra}
        <X-PRE-PROCESS cmd="include" data="template/${profile_template}.xml"/>
EOT

      # Generate ACLs
      my $ingress_cv = AnyEvent->condvar;
      AnyEvent::DNS::a( CCNQ::Install::catdns('ingress',$name,CCNQ::Install::fqdn), $ingress_cv );
      my @ingress = $ingress_cv->recv;
      debug("b2bua/carrier-sbc-config: Found ingress IPs ".join(',',@ingress));

      $acl_text .= qq(<list name="sbc-${name}" default="deny">);
      $acl_text .= join('',map { qq(<node type="allow" cidr="$_/32"/>) } @ingress);
      $acl_text .= qq(</list>);

      # Generate dialplan entries
      my $egress_cv = AnyEvent->condvar;
      AnyEvent::DNS::a( CCNQ::Install::catdns('egress',$name,CCNQ::Install::fqdn), $egress_cv );
      my @egress = $egress_cv->recv;
      debug("b2bua/carrier-sbc-config: Found egress IPs ".join(',',@egress));

      # XXX Only one IP supported at this time.
      # It's OK for a profile to not support 'egress' (e.g. signaling-server).
      my $egress = shift(@egress) || '';
      $dialplan_text .= <<"EOT";
        <X-PRE-PROCESS cmd="set" data="profile_name=${name}"/>
        <X-PRE-PROCESS cmd="set" data="sip_port=${port}"/>
        <X-PRE-PROCESS cmd="set" data="sip_ip=${internal_ip}"/>

        <X-PRE-PROCESS cmd="set" data="egress_target=${egress}"/>
        <X-PRE-PROCESS cmd="include" data="template/${dialplan_template}.xml"/>
EOT
    } # for $name

    my $sip_profile_file = CCNQ::B2BUA::install_dir(qw( sip_profiles ), "${b2bua_name}.xml" );
    CCNQ::Util::print_to($sip_profile_file,$sip_profile_text);

    my $acl_file = CCNQ::B2BUA::install_dir(qw( autoload_configs ), "${b2bua_name}.acl.xml" );
    CCNQ::Util::print_to($acl_file,$acl_text);

    my $dialplan_file = CCNQ::B2BUA::install_dir(qw( dialplan ), "${b2bua_name}.xml" );
    CCNQ::Util::print_to($dialplan_file,$dialplan_text);

    CCNQ::B2BUA::finish();
    $mcv->send(CCNQ::AE::SUCCESS);
}

'CCNQ::B2BUA::Stick';

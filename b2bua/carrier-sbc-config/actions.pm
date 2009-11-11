use CCNQ::B2BUA;
use CCNQ::Install;
use AnyEvent::DNS;
use File::Spec;
use File::Path;

{
  install => sub {
    use Logger::Syslog;

    my ($params,$context,$mcv) = @_;
    my $b2bua_name = 'carrier-sbc-config';

    debug("b2bua/carrier-sbc-config: Installing autoload_configs");
    for my $name (qw( carrier-sbc-config )) {
      CCNQ::B2BUA::copy_file($b2bua_name,qw( autoload_configs ),"${name}.acl.xml");
    }

    debug("b2bua/carrier-sbc-config: Installing dialplan/template");
    for my $name (qw( dash level3 option-service transparent )) {
      CCNQ::B2BUA::copy_file($b2bua_name,qw( dialplan template ),"${name}.xml");
    }

    my $profile_path = File::Spec->catfile(CCNQ::B2BUA::freeswitch_install_conf,'sip_profiles');
    debug("b2bua/carrier-sbc-config: Creating path $profile_path");
    File::Path::mkpath([$profile_path]);
    my $dialplan_path = File::Spec->catfile(CCNQ::B2BUA::freeswitch_install_conf,'dialplan');
    debug("b2bua/carrier-sbc-config: Creating path $dialplan_path");
    File::Path::mkpath([$dialplan_path]);

    $context->{resolver} = AnyEvent::DNS::resolver;

    # sip_profile
    for my $name qw( dash-911 dash level3 option-service ) {
      # Figure out whether we have all the data to configure the profile.
      # We need to have at least:
      #   port      -- TXT record of the SIP port to use (externally)
      #                         The internal port is always $external_port + 10000
      #   public    -- A record of our external SIP IP
      #   private   -- A record of our internal SIP IP
      # and zero or more of:
      #   ingress    -- A records with the IP address of the carrier's potential origination SBC
      #   egress     -- A record(s) with the IP address of the carrier's termination SBC

      my $extra = '';
      my $profile_template = 'sbc-nomedia';
      my $dialplan_template = $name;

      $extra = q(<X-PRE-PROCESS cmd="set" data="global_codec_prefs=PCMU@8000h@20i"/>),
      $dialplan_template = 'dash'
        if $name =~ /^dash/;
      $profile_template = 'sbc-media'
        if $name eq 'dash-911';

      debug("b2bua/carrier-sbc-config: Creating configuration for profile $name, if used.");

      my $port_dn = CCNQ::Install::catdns('port',$name,fqdn);
      my $port_cv = AnyEvent->condvar;
      AnyEvent::DNS::txt( $port_dn, $port_cv );
      my ($external_port) = $port_cv->recv;
      debug("Query TXT $port_dn -> $external_port");

      my $public_dn = CCNQ::Install::catdns('public',$name,fqdn);
      my $public_cv = AnyEvent->condvar;
      AnyEvent::DNS::a( $public_dn, $public_cv );
      my ($public_ip) = $public_cv->recv;
      debug("Query A $public_dn -> $public_ip");

      my $private_dn = CCNQ::Install::catdns('private',$name,fqdn);
      my $private_cv = AnyEvent->condvar;
      AnyEvent::DNS::a( $private_dn, $private_cv );
      my ($private_ip) = $private_cv->recv;
      debug("Query A $private_dn -> $private_ip");

      next unless defined($external_port) && defined($public_ip) && defined($private_ip);

      debug("b2bua/carrier-sbc-config: Found external port $external_port");
      my $internal_port = $external_port + 10000;
      debug("b2bua/carrier-sbc-config: Using internal port $internal_port");

      # Generate sip_profile entries
      my $sip_profile_file = File::Spec->catfile($profile_path,"${name}.xml");
      my $sip_profile_text = <<"EOT";
        <X-PRE-PROCESS cmd="set" data="profile_name=${name}"/>
        <X-PRE-PROCESS cmd="set" data="internal_sip_port=${internal_port}"/>
        <X-PRE-PROCESS cmd="set" data="external_sip_port=${external_port}"/>
        <X-PRE-PROCESS cmd="set" data="internal_sip_ip=${private_ip}"/>
        <X-PRE-PROCESS cmd="set" data="external_sip_ip=${public_ip}"/>
        ${extra}
        <X-PRE-PROCESS cmd="include" data="template/${profile_template}.xml"/>
EOT
      CCNQ::Install::print_to($sip_profile_file,$sip_profile_text);

      # Generate ACLs
      my $ingress_cv = AnyEvent->condvar;
      AnyEvent::DNS::a( CCNQ::Install::catdns('ingress',$name,fqdn), $ingress_cv );
      my @ingress = $ingress_cv->recv;
      debug("b2bua/carrier-sbc-config: Found ingress IPs ".join(',',@ingress));

      my $acl_file = File::Spec->catfile(CCNQ::B2BUA::freeswitch_install_conf,'autoload_configs',"${name}.acl.xml");
      my $acl_text = qq(<list name="sbc-${name}" default="deny">);
      $acl_text .= join('',map { qq(<node type="allow" cidr="$_/32"/>) } @ingress);
      $acl_text .= qq(</list>);
      CCNQ::Install::print_to($acl_file,$acl_text);

      # Generate dialplan entries
      my $egress_cv = AnyEvent->condvar;
      AnyEvent::DNS::a( CCNQ::Install::catdns('egress',$name,fqdn), $egress_cv );
      my @egress = $egress_cv->recv;
      debug("b2bua/carrier-sbc-config: Found egress IPs ".join(',',@egress));

      # XXX Only one IP supported at this time.
      my $egress = shift @egress;
      my $dialplan_file = File::Spec->catfile($dialplan_path,"${name}.xml");
      my $dialplan_text = <<"EOT";
        <X-PRE-PROCESS cmd="set" data="profile_name=${name}"/>
        <X-PRE-PROCESS cmd="set" data="internal_sip_port=${internal_port}"/>
        <X-PRE-PROCESS cmd="set" data="external_sip_port=${external_port}"/>
        <X-PRE-PROCESS cmd="set" data="internal_sip_ip=${private_ip}"/>
        <X-PRE-PROCESS cmd="set" data="external_sip_ip=${public_ip}"/>

        <X-PRE-PROCESS cmd="set" data="ingress_target=inbound-proxy.\$\${cluster_name}"/>
        <X-PRE-PROCESS cmd="set" data="egress_target=${egress}"/>
        <X-PRE-PROCESS cmd="include" data="template/${dialplan_template}.xml"/>
EOT
      CCNQ::Install::print_to($dialplan_file,$dialplan_text);
    } # for $name

    return;
  },
}

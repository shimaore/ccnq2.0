use CCNQ::B2BUA;

{
  install => sub {
    my $b2bua_name = 'carrier-sbc-config';

    # autoload_configs
    for my $name (qw( acl.carrier-sbc-config )) {
      CCNQ::B2BUA::copy_file($b2bua_name,qw( autoload_configs ),"${name}.conf.xml");
    }

    # dialplan
    for my $name (qw( dash-911 dash-sbc1 level3-sbc1 sotel-sbc1 )) {
      CCNQ::B2BUA::copy_file($b2bua_name,qw( dialplan ),"${name}.xml");
    }

    # dialplan/template
    for my $name (qw( dash level3 transparent )) {
      CCNQ::B2BUA::copy_file($b2bua_name,qw( dialplan template ),"${name}.xml");
    }

    # sip_profile
    for my $name qw( dash-911 dash-sbc1 global-crossing-sbc1 level3-sbc1 sotel-sbc1 ) {
      CCNQ::B2BUA::copy_file($b2bua_name,qw( sip_profiles ),"${name}.xml");
    }
    
    return;
  },
}
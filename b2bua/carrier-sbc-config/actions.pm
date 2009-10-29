use CCNQ::B2BUA;

use constant base_name => 'carrier-sbc-config';

{
  install => sub {
    # autoload_configs
    for my $name in qw( acl.carrier-sbc-config ) {
      CCNQ::B2BUA::copy_file(base_name,qw( autoload_configs ),"${name}.conf.xml");
    }

    # dialplan
    for my $name in qw( dash-911 dash-sbc1 level3-sbc1 sotel-sbc1 ) {
      CCNQ::B2BUA::copy_file(base_name,qw( dialplan ),"${name}.xml");
    }

    # dialplan/template
    for my $name in qw( dash level3 transparent ) {
      CCNQ::B2BUA::copy_file(base_name,qw( dialplan template ),"${name}.xml");
    }

    # sip_profile
    for my $name in qw( dash-911 dash-sbc1 global-crossing-sbc1 level3-sbc1 sotel-sbc1 ) {
      CCNQ::B2BUA::copy_file(base_name,qw( sip_profiles ),"${name}.xml");
    }
  },
}
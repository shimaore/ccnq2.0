use CCNQ::B2BUA;

use constant base_name => 'client-sbc-config';

{
  install => sub {
    # dialplan
    for my $name (qw( plain )) {
      CCNQ::B2BUA::copy_file(base_name,qw( dialplan ),"${name}.xml");
    }

    # sip_profile
    for my $name (qw( plain )) {
      CCNQ::B2BUA::copy_file(base_name,qw( sip_profiles ),"${name}.xml");
    }
  },
}
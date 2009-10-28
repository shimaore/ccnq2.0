package CCNQ::Proxy;

use CCNQ::Install;
use File::Temp;

use constant runtime_opensips_cfg => '/etc/opensips/opensips.cfg';
use constant runtime_opensips_sql => '/etc/opensips/opensips.sql';

use constant proxy_base_lib => File::Spec->catfile(CCNQ::Install::SRC,qw( proxy base lib ));
use constant opensips_base_lib => File::Spec->catfile(CCNQ::Install::SRC,qw( proxy base opensips));

1;
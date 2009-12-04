use Test::More;

require_ok( 'CCNQ::Object' );
require_ok( 'CCNQ::Install' );

$ENV{'CCNQ_cookie'} = 'ABCD';
is(CCNQ::Install::cookie(),'ABCD','cookie from environment');

$ENV{'CCNQ_host_name'} = 'test-host';
$ENV{'CCNQ_domain_name'} = 'private.example.net';
is(CCNQ::Install::fqdn,'test-host.private.example.net','fqdn');

done_testing();
1;
use Test::More;

require_ok( 'CCNQ::Object' );
require_ok( 'CCNQ::Install' );

$ENV{'CCNQ_cookie'} = 'ABCD';
is(CCNQ::Install::cookie(),'ABCD','cookie from environment');

done_testing();
1;
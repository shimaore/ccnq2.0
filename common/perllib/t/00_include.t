use Test::More;

require_ok( 'CCNQ::Object' );
require_ok( 'CCNQ::Install' );

$ENV{CCNQ::Install::ENV_Prefix.CCNQ::Install::cookie_tag} = 'ABCD';
is(CCNQ::Install::cookie(),'ABCD','CCNQ::Install::cookie()');

done_testing();
1;
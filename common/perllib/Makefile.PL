use inc::Module::Install;

# use Module::Install::Share;

# Define metadata
name          'CCNQ';
all_from      'lib/CCNQ.pm';
license       'gpl';

# Specific dependencies
requires      'File::ShareDir'            => '1.01';
requires      'File::Spec'                => 0; # '3.2501'
requires      'File::Copy'                => 0;
requires      'File::Path'                => 0;
requires      'EV'                        => '3.9';
requires      'AnyEvent'                  => '5.24';
requires      'AnyEvent::DNS'             => 0; # should be the same as AnyEvent
requires      'AnyEvent::XMPP'            => '0.51';
requires      'AnyEvent::HTTPD'           => '0.84';
requires      'AnyEvent::HTTP'            => 0;
requires      'AnyEvent::Util'            => 0; # should be the same as AnyEvent
requires      'AnyEvent::Watchdog::Util'  => '1.0';
requires      'AnyEvent::DBI'             => '2.0';

requires      'CouchDB::View'             => 0;
requires      'AnyEvent::CouchDB'         => '1.20';

requires      'Async::Interrupt'          => 0;
requires      'Guard'                     => 0;
requires      'Net::SSLeay'               => 0;

requires      'Logger::Syslog'            => 0;
requires      'JSON'                      => '2.17';
requires      'JSON::XS'                  => '2.27';
requires      'Memoize'                   => 0;
requires      'constant::defer'           => '2';
requires      'IO::Scalar'                => 0;

requires      'Digest::SHA1'              => 0;
requires      'Carp'                      => 0;
requires      'MIME::Base64'              => 0;

# Dependencies for the api
requires      'AnyEvent::HTTP'            => '1.44';

requires      'UNIVERSAL::require'        => 0;

test_requires 'Test::More' => '0.94';

# Copy everything in 'share'.
install_share;

install_script 'ccnq2_upgrade';
install_script 'ccnq2_restart';
install_script 'ccnq2_xmpp_agent';
install_script 'ccnq2_sip_traces';
install_script 'ccnq2_crontab_cdr';

WriteAll;

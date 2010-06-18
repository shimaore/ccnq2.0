use inc::Module::Install;

# Define metadata
name          'CCNQ-Portal';
all_from      'lib/CCNQ/Portal.pm';
author        q{Stephane Alnet <stephane@shimaore.net>};
license       'gpl';

# Specific dependencies
requires      'CCNQ'                      => '0.050';

requires      'File::ShareDir'            => '1.01';
requires      'File::Spec'                => 0; # '3.2501'

requires      'Dancer'                    => '1.1803';
requires      'Dancer::Session::Memcached' => 0;
requires      'Dancer::Logger::Syslog'    => 0;
requires      'Template'                  => 0;

requires      'MIME::Base64'              => 0;

requires      'CGI::Untaint'              => 0;
requires      'CGI::Untaint::email'       => 0;

requires      'Net::LDAP'                 => 0;

## Portal requirements
requires      'Locale::Maketext::Lexicon'     => 0;
requires      'Lingua::EN::Numbers::Ordinate' => 0;
requires      'Lingua::FR::Numbers'           => 0;
requires      'Lingua::FR::Numbers::Ordinate' => 0;
## Proxy requirements
# requires      'DBI' => 0;

test_requires 'Test::More' => '0.94';
# Required to test with Dancer::Session::Cookies.
test_requires 'Crypt::CBC' => 0;
test_requires 'String::CRC32' => 0;
test_requires 'Crypt::Rijndael' => 0;

# Copy everything in 'share'.
install_share;

WriteAll;

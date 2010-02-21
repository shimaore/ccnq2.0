use inc::Module::Install;

# Define metadata
name          'CCNQ-Portal';
all_from      'lib/CCNQ/Portal.pm';

# Specific dependencies
requires      'CCNQ'                      => '0.01';

requires      'Dancer'                    => '1.155'; # pre-1.160 github
requires      'CGI::FormBuilder'          => '3.0501';

## Portal requirements
requires      'Locale::Maketext::Lexicon'     => 0;
requires      'Lingua::EN::Numbers::Ordinate' => 0;
requires      'Lingua::FR::Numbers::Ordinate' => 0;
## Proxy requirements
# requires      'DBI' => 0;

test_requires 'Test::More' => 0;
# Required to test with Dancer::Session::Cookies.
test_requires 'Crypt::CBC' => 0;
test_requires 'String::CRC32' => 0;
test_requires 'Crypt::Rijndael' => 0;

# Copy everything in 'share'.
install_share;

WriteAll;

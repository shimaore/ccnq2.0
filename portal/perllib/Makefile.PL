use inc::Module::Install;

# Define metadata
name          'CCNQ-Portal';
all_from      'lib/CCNQ/Portal.pm';

# Specific dependencies
requires      'CCNQ'                      => '0.01';

requires      'Dancer'                    => '1.130';
requires      'CGI::FormBuilder'          => '3.0501';

## Portal requirements
requires      'Locale::Maketext::Lexicon'     => 0;
requires      'Lingua::EN::Numbers::Ordinate' => 0;
requires      'Lingua::FR::Numbers::Ordinate' => 0;
## Proxy requirements
# requires      'DBI' => 0;

test_requires 'Test::More' => 0;

# Copy everything in 'share'.
install_share;

WriteAll;

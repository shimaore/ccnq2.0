use inc::Module::Install;

# use Module::Install::Share;

# Define metadata
name          'CCNQ-Portal';
abstract      'Portal for ccnq2.0';
author        'Stephane Alnet <stephane@shimaore.net>';
version       '0.01';
license       'gpl';
perl_version  '5.008';

# Specific dependencies
requires      'CCNQ'                      => '0.01';

requires      'Dancer'                    => 0;

## Portal requirements
requires      'Locale::Maketext::Lexicon'     => 0;
requires      'Lingua::EN::Numbers::Ordinate' => 0;
requires      'Lingua::FR::Numbers::Ordinate' => 0;
## Proxy requirements
# requires      'DBI' => 0;

test_requires 'Test::More' => 0;

# Copy everything in 'share'.
install_share;

install_script 'ccnq2_upgrade';
install_script 'ccnq2_xmpp_agent';

WriteAll;

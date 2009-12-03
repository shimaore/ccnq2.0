use inc::Module::Install;

# Define metadata
name          'CCNQ';
abstract      'Distribution for ccnq2.0';
author        'Stephane Alnet <stephane@shimaore.net>';
version       '0.01';
license       'gpl';
perl_version  '5.008';

# Specific dependencies
requires      'File::Spec' => 0; # '3.2501'
requires      'File::Copy' => 0;
requires      'File::Path' => 0;
requires      'AnyEvent' => 0; # '5.202'
requires      'Logger::Syslog' => 0;
requires      'JSON' => 0;
## Portal requirements
# requires      'Locale::Maketext::Lexicon' => 0;
# requires      'Lingua::EN::Numbers::Ordinate' => 0;
# requires      'Lingua::FR::Numbers::Ordinate' => 0;
## Proxy requirements
# requires      'DBI' => 0;

test_requires 'Test::More' => 0;

WriteAll;

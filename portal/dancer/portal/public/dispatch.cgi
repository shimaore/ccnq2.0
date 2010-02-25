#!/opt/local/bin/perl
use Plack::Runner;
# XXX This should be a static path.
Plack::Runner->run('../app.psgi');

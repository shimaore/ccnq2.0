# PSGI application bootstraper for Dancer
use lib '/Users/stephane/Artisan/Telecoms/ccnq2.0/portal';
use portal;

use Dancer::Config 'setting';
setting apphandler  => 'PSGI';
Dancer::Config->load;

my $handler = sub {
    my $env = shift;
    my $request = Dancer::Request->new($env);
    Dancer->dance($request);
};

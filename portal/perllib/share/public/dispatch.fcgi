#!/usr/bin/env perl
use Plack::Handler::FCGI;
use CCNQ::Portal;
my $app = do(CCNQ::Portal::SRC.'dancer/app.psgi');
my $server = Plack::Handler::FCGI->new(nproc  => 5, detach => 1);
$server->run($app);

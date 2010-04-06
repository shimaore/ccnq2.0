#!/usr/bin/env perl
use Plack::Runner;
use CCNQ::Portal;
Plack::Runner->run(CCNQ::Portal::SRC.'dancer/app.psgi');

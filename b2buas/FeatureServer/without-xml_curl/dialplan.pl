#!/usr/bin/perl
# (c) 2009 Stephane Alnet
# License: GPL3

# This script must be installed on the server that runs the
# FreeSwitch instance we want to update, alongside dialplan.sh

use strict; use warnings;

use Net::CouchDb;

# Modify DB_URI if the database is hosted on another system.
# For example:
# use constant DB_URI => 'https://db1.'.DOMAIN().':5985
use constant DB_URI => $ARGV[0];
use constant DB_NAME => 'dialplan';

sub run {
  my $cdb = new Net::CouchDb(uri => DB_URI);
  # Updated for CouchDB 0.9
  my $results = $cdb->db(DB_NAME)->call('GET','_design/freeswitch/_view/xml_nocontext');
  my $res = '';
  if($results && $results->{rows})
  {
    $res = join("\n", map { $_->{value} } @{$results->{rows}});
  }
  print "<include>\n".$res."\n</include>\n";
}

run();

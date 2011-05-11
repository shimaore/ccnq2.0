#!/usr/bin/perl
use strict; use warnings;
our $session;

# XXX TODO Replace with http://wiki.freeswitch.org/wiki/Mod_cidlookup

# use constant CNAM_URI => 'https://cnam.sotelips.net:9443/callingname.yaws?Number=';
use constant CNAM_URI => 'https://cnam.sotelips.net:9443/1';

sub info
{
  freeswitch::consoleLog("info", "CNAM: ".join(' ',@_)."\n");
}

sub cnam_run {

  info('Starting');
  my $cid = $session->getVariable('caller_id_number');
  info('CID:',$cid);
  if( $cid =~ /^[+]?1?(\d{10})$/ )
  {
    my $number = $1;
    info('Number:',$number);

    use LWP::UserAgent;
    my $ua = LWP::UserAgent->new;
    my $req = HTTP::Request->new(
      GET => CNAM_URI.$number
    );

    my $res = $ua->request($req);

    if($res->is_success) {
      my $string = $res->content;
      $string =~ s/[^\w,.@-]/ /g;
      $string =~ s/\s+$//g;
      $session->setVariable('effective_caller_id_name',$string);
      info('Got calling name:',$string);
    }
    else
    {
      info('Error:',$res->status_line);
      $session->setVariable('effective_caller_id_name','No data');
    }
  }
  else
  {
    info('Improper CID format',$cid);
  }
  info('Done');
}

cnam_run();
1;

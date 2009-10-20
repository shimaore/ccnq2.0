#!/usr/bin/perl
use strict; use warnings;
use utf8;
use AnyEvent;
# *** The EV module is recommended for even better performance, unless you
# *** have to use one of the other adaptors (Event, Glib, Tk, etc.).
# *** The Async::Interrupt module is highly recommended to efficiently avoid
# *** race conditions in/with other event loops.

use AnyEvent::XMPP::IM::Connection;

use constant JID        => '';
use constant PASSWORD   => '';
use constant HOST       => '';
use constant NICK       => ''; # Must be unique if used 

unless (@ARGV >= 1) { die "sendmsg [-t <file>] [-j] <destination jid>\n" }

our $fh = \*STDIN;
our $name = undef;
if($ARGV[0] eq '-t')
{
  shift;
  $name = shift;
  open($fh,'<',$name) or die "$name: $!";
} else {
  $fh = \*STDIN;
}

use AnyEvent::XMPP::Ext::Disco;
our $disco = new AnyEvent::XMPP::Ext::Disco;

our $muc = undef;
if($ARGV[0] eq '-j')
{
  shift;
  use AnyEvent::XMPP::Ext::MUC;
  $muc = new AnyEvent::XMPP::Ext::MUC( disco => $disco );
}

our $dest = shift;

my $j = AnyEvent->condvar;

my $con =
   AnyEvent::XMPP::IM::Connection->new (
      jid      => JID,
      password => PASSWORD,
      host     => HOST,
      initial_presence => -10,
      debug    => 1
   );

if($disco) {
  $con->add_extension($disco);
}

if($muc) {
  $con->add_extension($muc);
}

our $w; 
$con->reg_cb (
   session_ready => sub {
      our ($con) = @_;
      # print STDERR "Connected as " . $con->jid . "\n";
      $con->send_presence("I'm a Bad Robot!");
      if($muc) {
        $muc->join_room($con,$dest,NICK);
      }

      our $room = undef;
      $w = AnyEvent->io (fh => $fh, poll => 'r', cb => sub {
        my $input = <$fh>;

        # End of stream
        if(!defined($input)) {
          if($name) {
            close($fh) or die "$name: $!";
            open($fh,'<',$name) or die "$name: $!";
          } else {
            $j->send();
          }
          return;
        }

        chomp($input);
        return if $input =~ /^\s*$/;
        ## print "Sending message to $dest:\n$input\n";
        my $immsg;
        if($muc) {
          my $room = $muc->get_room ($con, $dest);
          if($room) {
            $immsg = $room->make_message(body => $input);
            $immsg->send();
          } else {
            warn("Not joined yet");
          }
        } else {
          $immsg = new AnyEvent::XMPP::IM::Message(to => $dest, body => $input);
          $immsg->send($con);
        }
      });
   },
   join => sub {
      my ($con,$room,$user) = @_;
      # print $user->nick . " joined $room\n";
   },
   enter => sub {
      my ($con,$room,$user) = @_;
      # print $user->nick . " joined $room\n";
   },
   message => sub {
      my ($con, $msg) = @_;
      # print "Message from " . $msg->from . ":\n" . $msg->any_body . "\n---\n";
   },
   error => sub {
      my ($con, $error) = @_;
      warn "Error: " . $error->string . "\n";
   },
   disconnect => sub {
      my ($con, $h, $p, $reason) = @_;
      warn "Disconnected from $h:$p: $reason\n";
      $j->broadcast;
   }
);

## print "Trying to connect...\n";
$con->connect ();

$j->recv;


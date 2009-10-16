#!/usr/bin/perl
use strict; use warnings;
use utf8;

use constant JID        => '';
use constant PASSWORD   => '';
use constant HOST       => '';
use constant NICK       => ''; # Must be unique if used 
use constant MUC_ROOM   => '';

# Restart ourselves

our $selves = $0;
sub restart {
  exec($selves);
}

# AnyEvent says:
# *** The EV module is recommended for even better performance, unless you
# *** have to use one of the other adaptors (Event, Glib, Tk, etc.).
# *** The Async::Interrupt module is highly recommended to efficiently avoid
# *** race conditions in/with other event loops.
use AnyEvent;
use AnyEvent::XMPP::IM::Connection;

use AnyEvent::XMPP::Ext::Disco;
our $disco = new AnyEvent::XMPP::Ext::Disco or restart();

use AnyEvent::XMPP::Ext::MUC;
our $muc = new AnyEvent::XMPP::Ext::MUC( disco => $disco ) or restart();

use AnyEvent::XMPP::Ext::Pubsub;
our $pubsub = new AnyEvent::XMPP::Ext::Pubsub() or restart();

# Loops until we are asked to restart ourselves (e.g. after upgrade)
my $j = AnyEvent->condvar;

my $con =
   AnyEvent::XMPP::IM::Connection->new (
      jid               => JID,
      password          => PASSWORD,
      host              => HOST,
      initial_presence  => -10,
      debug             => 1
   );

$con->add_extension($disco);
$con->add_extension($muc);
$con->add_extension($pubsub);

$con->reg_cb (
   session_ready => sub {
      our ($con) = @_;
      # print STDERR "Connected as " . $con->jid . "\n";
      $con->send_presence("present");
      if($muc) {
        $muc->join_room($con,MUC_ROOM,NICK);
      }
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

   # MUC-specific
   enter => sub {
      my ($con,$room,$user) = @_;
      # print $user->nick . " (me) joined $room\n";
   },
   leave => sub {
      my ($con,$room,$user) = @_;
      # print $user->nick . " (me) left $room\n";
   },
   join_error => sub {
     my ($con,$room,$error) = @_;
     warn "Error: " . $error->string . "\n";
   }
   presence => sub {
     my ($con,$room,$user) = @_;
   }
   join => sub {
      my ($con,$room,$user) = @_;
      # print $user->nick . " joined $room\n";
   },
   part => sub {
     my ($con,$room,$user) = @_;
     # print $user->nick . " left $room\n";
   }
   
   pubsub_recv => sub {
     my ($con,)
   }
);

## print "Trying to connect...\n";
$con->connect ();

$j->recv;
restart();

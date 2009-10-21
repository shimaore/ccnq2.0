package CCNQ::XMPPAgent;
# Copyright (C) 2009  Stephane Alnet
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 3
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use CCNQ::Install;

use AnyEvent;
use AnyEvent::XMPP::IM::Connection;
use AnyEvent::XMPP::Ext::Disco;
use AnyEvent::XMPP::Ext::MUC;
use AnyEvent::XMPP::Ext::Pubsub;

use Logger::Syslog;

use JSON;

sub restart {
  error('restart');
  die 'restart'; # Intercepted by xmpp_agent.pl
}

=pod
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
=cut

sub send_message {
  my ($con,$dest,$content) = @_;
  my $msg = encode_json($content);
  my $immsg = new AnyEvent::XMPP::IM::Message(to => $dest, body => $msg);
  $immsg->send($con);
}

sub handle_message {
  my ($con,$function,$msg) = @_;
  my $content = decode_json($msg);
  debug("Decoded $content");
  error("Object received is not an hashref") unless ref($content) eq 'HASH';

  # XXX Need transaction and auth handling here.

  # Try to process the command.
  my $action = $content->{action};
  my $result = CCNQ::Install::attempt_run($function,$action,$content);

  if($result) {
    # XXX Need transaction and auth handling here.
    send_message($con,$msg->from,$result);
  }
}

sub run {
  my $function = shift;

  debug("Attempting to start XMPPAgent for function $function");

  # AnyEvent says:
  # *** The EV module is recommended for even better performance, unless you
  # *** have to use one of the other adaptors (Event, Glib, Tk, etc.).
  # *** The Async::Interrupt module is highly recommended to efficiently avoid
  # *** race conditions in/with other event loops.

  our $disco  = new AnyEvent::XMPP::Ext::Disco or restart();
  our $muc    = new AnyEvent::XMPP::Ext::MUC( disco => $disco ) or restart();
  our $pubsub = new AnyEvent::XMPP::Ext::Pubsub() or restart();

  # Loops until we are asked to restart ourselves (e.g. after upgrade)
  my $j = AnyEvent->condvar;

  my $con =
     AnyEvent::XMPP::IM::Connection->new (
        username          => CCNQ::Install::host_name,
        domain            => CCNQ::Install::domain_name,
        resource          => $function
        password          => CCNQ::Install::make_password($function,CCNQ::Install::xmpp_tag),
        # host              => HOST,
        initial_presence  => -10,
        'debug'           => 1,
     );

  $con->add_extension($disco);
  $con->add_extension($muc);
  $con->add_extension($pubsub);

  $con->reg_cb (
     session_ready => sub {
        our ($con) = @_;
        debug("Connected as " . $con->jid);
        $con->send_presence("present");
        for my $muc_room (@{CCNQ::Install::cluster_names}) {
          $muc->join_room($con,$muc_room);
        }
     },
     message => sub {
        my ($con, $msg) = @_;
        debug("Message from " . $msg->from . ":\n" . $msg->any_body . "\n---\n");
        handle_message($con,$function,$msg);
     },
     error => sub {
        my ($con, $error) = @_;
        error("Error: " . $error->string . "\n");
     },
     disconnect => sub {
        my ($con, $h, $p, $reason) = @_;
        error("Disconnected from $h:$p: $reason\n");
        $j->broadcast;
     }

     # MUC-specific
     enter => sub {
        my ($con,$room,$user) = @_;
        debug($user->nick . " (me) joined $room\n");
     },
     leave => sub {
        my ($con,$room,$user) = @_;
        debug($user->nick . " (me) left $room\n");
     },
     join_error => sub {
       my ($con,$room,$error) = @_;
       error("Error: " . $error->string . "\n");
       $j->broadcast;
     }
     presence => sub {
       my ($con,$room,$user) = @_;
       debug("presence");
     }
     join => sub {
        my ($con,$room,$user) = @_;
        debug($user->nick . " joined $room\n");
     },
     part => sub {
       my ($con,$room,$user) = @_;
       debug($user->nick . " left $room\n");
     }

     # PubSub-specific
     pubsub_recv => sub {
       my ($con) = @_;
       debug("pubsub_recv");
     }
  );

  info("Trying to connect...\n");
  $con->connect ();

  $j->recv;
  restart();
}

1;
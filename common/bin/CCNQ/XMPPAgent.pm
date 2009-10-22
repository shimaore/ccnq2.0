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

use constant handler_timeout => 20;

=pod
  Message format:

  activity : the activity UUID
  auth : activity submission authentication token
  action : action requested
  params : parameters sent to / from the action
  error : if present, an error occurred (activity submission failed)

=cut

sub _send_message {
  my ($con,$dest,$content) = @_;
  my $msg = encode_json($content);
  my $immsg = new AnyEvent::XMPP::IM::Message(to => $dest, body => $msg);
  $immsg->send($con);
}

sub authenticate_message {
  my ($content,$partner) = @_;
  # XXX Currently a noop
  return $response->{auth} eq 'authenticated';
}

sub authenticate_response {
  my ($response,$partner) = @_;
  $response->{auth} = 'authenticated';
}

sub handle_message {
  my ($context,$function,$msg) = @_;
  my $request = decode_json($msg);
  debug("Decoded $request");

  error("Object received is not an hashref"),
  return unless defined($request) && ref($request) eq 'HASH';

  error("Message contains no activity UUID"),
  return unless $request->{activity};

  error("Message authentication failed"),
  return unless authenticate_message($request,$msg->from);

  # Try to process the command.
  my $action = $request->{action};
  error("No action was defined"), return unless defined $request;

  our $response = {};

  my $w = AnyEvent->timer( after => handler_timeout, cb => sub {
    undef $w;
    if($response) {
      $response->{activity} = $query->{activity};
      $response->{action} = $query->{action};
      authenticate_response($response,$msg->from);
      _send_message($context->{connection},$msg->from,$response);
    }
  });

  $response = CCNQ::Install::attempt_run($function,$action,$request->{params},$context);
  $w->send;
  return $response;
}

sub start {
  our ($function,$j) = @_;

  debug("Attempting to start XMPPAgent for function $function");

  # AnyEvent says:
  # *** The EV module is recommended for even better performance, unless you
  # *** have to use one of the other adaptors (Event, Glib, Tk, etc.).
  # *** The Async::Interrupt module is highly recommended to efficiently avoid
  # *** race conditions in/with other event loops.

  our $disco  = new AnyEvent::XMPP::Ext::Disco or return;
  our $muc    = new AnyEvent::XMPP::Ext::MUC( disco => $disco ) or return;
  our $pubsub = new AnyEvent::XMPP::Ext::Pubsub() or return;

  my $username = CCNQ::Install::host_name;
  my $domain   = CCNQ::Install::domain_name;
  my $resource = $function;
  my $password = CCNQ::Install::make_password(CCNQ::Install::xmpp_tag);

  debug("Attempting XMPP Connection for ${username}\@${domain}/${resource} using password $password.");

  my $con =
     AnyEvent::XMPP::IM::Connection->new (
        username          => $username,
        domain            => $domain,
        resource          => $resource,
        password          => $password,
        # host              => HOST,
        initial_presence  => -10,
        'debug'           => 1,
     );

  $con->add_extension($disco);
  $con->add_extension($muc);
  $con->add_extension($pubsub);

  our $context = {
    connection => $con,
    muc        => $muc,
    username   => $username,
    domain     => $domain,
    resource   => $resource,
  };

  $con->reg_cb (
     session_ready => sub {
        our ($con) = @_;
        debug("Connected as " . $con->jid);
        $con->send_presence("present");
        CCNQ::Install::attempt_run($function,'_session_ready',$context);
     },
     message => sub {
        my ($con, $msg) = @_;
        debug("Message from " . $msg->from . ":\n" . $msg->any_body . "\n---\n");
        handle_message($context,$function,$msg);
     },
     error => sub {
        my ($con, $error) = @_;
        error("Error: " . $error->string . "\n");
     },
     disconnect => sub {
        my ($con, $h, $p, $reason) = @_;
        error("Disconnected from $h:$p: $reason\n");
        $j->send;
     },

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
       $j->send;
     },
     presence => sub {
       my ($con,$room,$user) = @_;
       debug("presence");
     },
     join => sub {
        my ($con,$room,$user) = @_;
        debug($user->nick . " joined $room\n");
     },
     part => sub {
       my ($con,$room,$user) = @_;
       debug($user->nick . " left $room\n");
     },

     # PubSub-specific
     pubsub_recv => sub {
       my ($con) = @_;
       debug("pubsub_recv");
     },
  );

  info("Trying to connect...\n");
  $con->connect ();
}

1;
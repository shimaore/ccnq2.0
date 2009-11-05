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

use strict; use warnings;

use CCNQ::Install;

use AnyEvent;
use AnyEvent::XMPP::IM::Connection;
use AnyEvent::XMPP::Ext::Disco;
use AnyEvent::XMPP::Ext::MUC;
use AnyEvent::XMPP::Ext::Pubsub;
use AnyEvent::XMPP::Util qw/split_jid/;

use Logger::Syslog;

use JSON;

use constant handler_timeout => 20;

=pod
  Subject format:

  activity : the activity UUID
  action : action requested
  auth : activity submission authentication token

  Body format:

  params : parameters sent to / from the action
  error : if present, an error occurred (activity submission failed)

=cut

sub _joined_muc {
  my ($context,$dest) = @_;
  $context->{joined_muc}->{$dest} = 1;
  if($context->{pending_muc}->{$dest}) {
    while(@{$context->{pending_muc}->{$dest}}) {
      my $ref = shift @{$context->{pending_muc}->{$dest}};
      _send_muc_message($context,$dest,$ref->{subject},$ref->{body});
    }
  }
}

sub _left_muc {
  my ($context,$dest) = @_;
  delete $context->{joined_muc}->{$dest};
}

sub send_muc_message {
  my ($context,$dest,$subject,$body) = @_;
  if($context->{joined_muc}->{$dest}) {
    return _send_muc_message($context,$dest,$subject,$body);
  } else {
    debug("send_muc_message(): queuing for dest=$dest");
    $context->{pending_muc}->{$dest} ||= [];
    push @{$context->{pending_muc}->{$dest}}, { subject => $subject, body => $body };
    return ['warning','Message queued'];
  }
}

sub _send_muc_message {
  my ($context,$dest,$subject,$body) = @_;
  debug("_send_muc_message(): dest=$dest");
  my $room = $context->{muc}->get_room ($context->{connection}, $dest);
  if($room) {
    authenticate_response($subject);
    my $json_subject = encode_json($subject);
    my $json_body    = encode_json($body);
    my $immsg = $room->make_message(subject => $json_subject, body => $json_body);
    $immsg->send();
    $subject->{submitted} = time;
    return ['ok'];
  } else {
    warning("$dest: Not joined yet");
    return ['error','Not joined yet'];
  }
}

sub _send_im_message {
  my ($context,$dest,$subject,$body) = @_;
  debug("_send_im_message(): dest=$dest");
  authenticate_response($subject);
  my $json_subject = encode_json($subject);
  my $json_body    = encode_json($body);
  my $immsg = new AnyEvent::XMPP::IM::Message(to => $dest, subject => $json_subject, body => $json_body);
  use Carp;
  confess("No connection") unless $context->{connection};
  $immsg->send($context->{connection});
  $subject->{submitted} = time;
  return ['ok'];
}

=pod

  submit_activity($context,$activity)
    Submit the specified activity into the XMPP bus
    Can send a message to a room or an individual node.

=cut

sub submit_activity {
  my ($context,$activity) = @_;

  my $subject;
  @$subject{qw(activity action)} = @$activity{qw( activity action )};

  # Forward the activity to the proper MUC
  if($activity->{cluster_name}) {
    my $dest = $activity->{cluster_name}.'@'.$context->{domain};
    debug("submit_activity(): send_muc_message($dest,$subject->{activity},$subject->{action})");
    return _send_muc_message($context,$dest,$subject,$activity);
  } elsif($activity->{node_name}) {
    my $dest = $activity->{node_name}.'@'.$context->{domain};
    debug("submit_activity(): send_muc_message($dest,$subject->{activity},$subject->{action})");
    return _send_im_message($context,$dest,$subject,$activity);
  }
  return ['error','No destination specified'];
}



sub authenticate_message {
  my ($content,$partner) = @_;
  # XXX Currently a noop
  return $content->{auth} eq 'authenticated';
}

sub authenticate_response {
  my ($subject,$partner) = @_;
  $subject->{auth} = 'authenticated';
}

sub handle_message {
  my ($context,$msg) = @_;
  my $function = $context->{function};

  error("No subject, ignoring message"),
  return unless $msg->subject;

  my $request_subject = decode_json($msg->subject);
  my $request_body    = decode_json($msg->any_body);

  error("Object received is not an hashref"),
  return unless defined($request_subject) && ref($request_subject) eq 'HASH';

  error("Message contains no activity UUID"),
  return unless $request_subject->{activity};

  error("Message contains no action"),
  return unless $request_subject->{action};

  error("Message authentication failed"),
  return unless authenticate_message($request_subject,$msg->from);

  # Try to process the command.
  my $action = $request_subject->{action};

  my $process_response = sub {
    my $response = shift;
    if($response) {
      my $subject = { map { $_=>$request_subject->{$_} } qw(activity action) };
      _send_im_message($context,$msg->from,$subject,$response);
    }
  };

  my $response = {};

  my $w;
  $w = AnyEvent->timer( after => handler_timeout, cb => sub {
    undef $w;
    info("function $function action $action Timed Out");
    $process_response->($response);
  });

  my $sub = CCNQ::Install::attempt_run($function,$action,$request_body,$context);
  $response = $sub->();
  undef $w;
  $process_response->($response);
  return $response;
}

sub join_cluster_room {
  my ($context) = @_;
  my $muc_jid = CCNQ::Install::make_muc_jid($context->{cluster});
  my $nick = $context->{function}.','.rand();
  info("Attempting to join $muc_jid as $context->{function}");
  $context->{muc}->join_room($context->{connection},$muc_jid,$nick,{
    history => {seconds=>3600},
    create_instant => 1,
  });
}

sub start {
  my ($cluster_name,$role,$function,$program) = @_;

  debug("Starting XMPPAgent for function $function");

  # AnyEvent says:
  # *** The EV module is recommended for even better performance, unless you
  # *** have to use one of the other adaptors (Event, Glib, Tk, etc.).
  # *** The Async::Interrupt module is highly recommended to efficiently avoid
  # *** race conditions in/with other event loops.

  my $disco  = new AnyEvent::XMPP::Ext::Disco or return;
  my $muc    = new AnyEvent::XMPP::Ext::MUC( disco => $disco ) or return;

  my $pubsub = new AnyEvent::XMPP::Ext::Pubsub() or return;

  my $username = CCNQ::Install::host_name;
  my $domain   = CCNQ::Install::domain_name;
  my $resource = $function;
  my $password = CCNQ::Install::make_password(CCNQ::Install::xmpp_tag);

  debug("Creating XMPP Connection for ${username}\@${domain}/${resource} using password $password.");

  my $con =
     AnyEvent::XMPP::IM::Connection->new (
        username          => $username,
        domain            => $domain,
        resource          => $resource,
        password          => $password,
        # host              => HOST,
        initial_presence  => 10,
        'debug'           => 1,
     );

  $con->add_extension($disco);
  $con->add_extension($muc);
  $con->add_extension($pubsub);

  my $context = {
    connection => $con,
    disco      => $disco,
    muc        => $muc,
    pubsub     => $pubsub,
    username   => $username,
    domain     => $domain,
    resource   => $resource,
    cluster    => $cluster_name,
    role       => $role,
    function   => $function,
    condvar    => $program,
    joined_muc  => {},
    pending_muc => {},
  };

  my $session_ready_sub = CCNQ::Install::attempt_run($function,'_session_ready',$context);

  $con->reg_cb (

    # AnyEvent::XMPP::Connection
    error => sub {
      my $con = shift;
      my ($error) = @_;
      error("xmpp error: " . $error->string);
    },
    connect => sub {
      my $con = shift;
      my ($host,$port) = @_;
      debug("connected to ${host}:${port}");
    },
    disconnect => sub {
      my $con = shift;
      my ($host,$port,$message) = @_;
      debug("disconnected from ${host}:${port}: ${message}");
      $program->end;
    },

    # AnyEvent::XMPP::IM::Connection
    session_ready => sub {
      my $con = shift;
      debug("Connected as " . $con->jid . " in function $context->{function}");
      $con->send_presence("present");
      # my ($user, $host, $res) = split_jid ($con->jid);
      $session_ready_sub->();
    },
    session_error => sub {
      my $con = shift;
      my ($error) = @_;
      error("session_error");
      $program->end;
    },
    presence_update => sub {
      my $con = shift;
      my ($roster, $contact, $old_presence, $new_presence)= @_;
      debug('presence_update '.$contact->jid);
    },
    presence_error => sub {
      my $con = shift;
      my ($error) = @_;
      error("presence_error: " . $error->string);
    },
    message => sub {
      my $con = shift;
      my ($msg) = @_;
      debug("IM Message from: " . $msg->from . "; subject: " . $msg->subject . "; body: " . $msg->any_body);
      handle_message($context,$msg);
    },
    message_error => sub {
      my $con = shift;
      my ($error) = @_;
      error("message_error: " . $error->string);
    },

    # PubSub-specific
    pubsub_recv => sub {
      my ($con) = @_;
      debug("pubsub_recv");
    },

  );

  $muc->reg_cb (
    # AnyEvent::XMPP::Ext::MUC
    # Can't register enter and join_error because join_room() already does
    # (and breaks if we try to).
    enter => sub {
      my $muc = shift;
      my ($room,$user) = @_;
      debug($user->nick . " (me) entered ".$room->jid);
      _joined_muc($context,$room->jid);
    },
    leave => sub {
      my $muc = shift;
      my ($room,$user) = @_;
      debug($user->nick . " (me) left ".$room->jid);
      _left_muc($context,$room->jid);
    },
    presence => sub {
      my $muc = shift;
      my ($room,$user) = @_;
      debug("presence");
    },
    join => sub {
      my $muc = shift;
      my ($room,$user) = @_;
      debug($user->nick . " joined ".$room->jid);
    },
    part => sub {
      my $muc = shift;
      my ($room,$user) = @_;
      debug($user->nick . " left ".$room->jid);
    },
    message => sub {
      my $muc = shift;
      my ($room,$msg,$is_echo) = @_;
      debug("In MUC room: " . $room->jid . ", message from: " . $msg->from . "; subject: " . $msg->subject . "; body: " . $msg->any_body);
      # my ($user, $host, $res) = split_jid ($msg->to);
      handle_message($context,$msg);
    },
  );

  info("Trying to connect...");
  $con->connect ();
}

1;
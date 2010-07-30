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
use CCNQ::AE::Run;

use AnyEvent;
use AnyEvent::XMPP::IM::Connection;
use AnyEvent::XMPP::Ext::Disco;
use AnyEvent::XMPP::Ext::MUC;
use AnyEvent::XMPP::Ext::Pubsub;
use AnyEvent::XMPP::Util qw/split_jid/;

use Logger::Syslog;

use JSON;
use MIME::Base64 ();

use constant handler_timeout => 20;
use constant MESSAGE_FRAGMENT_SIZE => 32*1024;

use constant STATUS_COMPLETED => 'completed';
use constant STATUS_FAILED    => 'failed';

=head1 XMPP MESSAGE BODY FORMAT

  Body format:

  activity : the activity UUID
  action : action requested
  auth : activity submission authentication token

  params : parameters sent to / from the action
  error : if present, an error occurred (activity submission failed)
  status : set to 'completed' or 'failed'; only found in responses

  A message is a request if no "status" body field is present.
  A message is a response if the "status" body field is present.

=cut

sub _joined_muc {
  my ($context,$dest) = @_;
  $context->{joined_muc}->{$dest} = 1;
  if($context->{pending_muc}->{$dest}) {
    while(@{$context->{pending_muc}->{$dest}}) {
      my $ref = shift @{$context->{pending_muc}->{$dest}};
      _send_muc_message($context,$dest,$ref->{body});
    }
  }
}

sub _left_muc {
  my ($context,$dest) = @_;
  delete $context->{joined_muc}->{$dest};
}

sub send_muc_message {
  my ($context,$dest,$body) = @_;
  if($context->{joined_muc}->{$dest}) {
    return _send_muc_message($context,$dest,$body);
  } else {
    debug("send_muc_message(): queuing for dest=$dest");
    $context->{pending_muc}->{$dest} ||= [];
    push @{$context->{pending_muc}->{$dest}}, { body => $body };

    exists $context->{joined_muc}->{$dest} or do {
      $context->{joined_muc}->{$dest} ||= 0;
      _join_room($context,$dest) ;
    };

    return ['warning','Message queued'];
  }
}

sub _send_muc_message {
  my ($context,$dest,$body) = @_;
  debug("_send_muc_message(): dest=$dest");
  my $room = $context->{muc}->get_room ($context->{connection}, $dest);
  if($room) {
    authenticate_response($body);
    my $json_body    = encode_json($body);
    my $immsg = $room->make_message(body => $json_body);
    $immsg->send();
    return ['ok'];
  } else {
    warning("$dest: Not joined yet");
    return ['error','Not joined yet'];
  }
}

sub _send_im_message {
  my ($context,$dest,$body) = @_;
  authenticate_response($body);
  my $json_body    = encode_json($body);
  debug("_send_im_message(): dest=$dest, body=$json_body");
  use Carp;
  confess("No connection") unless $context->{connection};

  # If the body is too long, split the JSON into multiple fragments.
  if(length($json_body) > MESSAGE_FRAGMENT_SIZE) {
    my $chunk_max = int(length($json_body)/MESSAGE_FRAGMENT_SIZE);
    my $message_id = rand();
    debug("_send_im_message(): splitting into $chunk_max fragments, message_id = $message_id");
    for my $chunk (0..$chunk_max) {
      my $offset = $chunk*MESSAGE_FRAGMENT_SIZE;
      my $last   = $chunk == $chunk_max;
      my $fragment_content = substr($json_body,$offset,MESSAGE_FRAGMENT_SIZE);
      my $fragment = {
        message_id => $message_id,
        offset     => $offset,
        last       => $last,
        fragment   => MIME::Base64::encode($fragment_content),
      };
      my $fragment_body = encode_json($fragment);
      my $immsg = new AnyEvent::XMPP::IM::Message(to => $dest, body => $fragment_body);
      $immsg->send($context->{connection});
      debug("_send_im_message(): sent fragment $chunk of $chunk_max");
    }
  } else {
    my $immsg = new AnyEvent::XMPP::IM::Message(to => $dest, body => $json_body);
    $immsg->send($context->{connection});
  }
  return ['ok'];
}

=pod

  submit_activity($context,$activity)
    Submit the specified activity into the XMPP bus
    Can send a message to a room or an individual node.

=cut

sub submit_activity {
  my ($context,$activity) = @_;

  # Forward the activity to the proper MUC
  if($activity->{cluster_name}) {
    my $dest = CCNQ::Install::make_muc_jid($activity->{cluster_name});
    debug("submit_activity(): send_muc_message($dest,$activity->{activity},$activity->{action})");
    return send_muc_message($context,$dest,$activity);
  } elsif($activity->{node_name}) {
    my $dest = $activity->{node_name}.'@'.$context->{domain};
    debug("submit_activity(): send_im_message($dest,$activity->{activity},$activity->{action})");
    return _send_im_message($context,$dest,$activity);
  }
  return ['error','No destination specified'];
}



sub authenticate_message {
  my ($content,$partner) = @_;
  # XXX Currently a noop
  return $content->{auth} eq 'authenticated';
}

sub authenticate_response {
  my ($body,$partner) = @_;
  $body->{auth} = 'authenticated';
}

=head2  handle_message($context,$msg)

Handles $msg (an XMPP IM message, which should have a JSON content) in
the context $context, and return an AnyEvent condvar.

Returns undef if the message could not be processed.

=cut

sub handle_message {
  my ($context,$msg) = @_;
  my $function = $context->{function};

  my $request_body;
  eval {
    $request_body    = decode_json($msg->any_body);
  };
  error("Invalid body: $@"),
  return if $@;

  error("Object received is not an hashref"),
  return unless defined($request_body) && ref($request_body) eq 'HASH';

  if($request_body->{fragment}) {

    error("No message_id"),
    return unless defined $request_body->{message_id};

    error("No offset"),
    return unless defined $request_body->{offset};

    my $message_id  = $request_body->{message_id};
    my $offset      = $request_body->{offset};

    $context->{fragments}->{$message_id} = ''
      if ! exists($context->{fragments}->{$message_id});

    if($offset != length($context->{fragments}->{$message_id})) {
      delete $context->{fragments}->{$message_id};
      error("Out-of-order fragment (offset=$offset)");
      return;
    }

    my $decoded_fragment = MIME::Base64::decode($request_body->{fragment});
    $context->{fragments}->{$message_id} .= $decoded_fragment;
    if($request_body->{last}) {
      # Last fragment received, process.
      eval {
        $request_body = decode_json( delete $context->{fragments}->{$message_id} );
      };
      error("Object received is not an hashref"),
      return unless defined($request_body) && ref($request_body) eq 'HASH';
    } else {
      # Wait for more fragments.
      # XXX Lost fragments will result in leaking memory (since e.g. a started
      # reconstruction may never complete).
      return;
    }
  }

  error("Message contains no activity UUID"),
  return unless $request_body->{activity};

  error("Message contains no action"),
  return unless $request_body->{action};

  error("Message authentication failed"),
  return unless authenticate_message($request_body,$msg->from);

  # Try to process the command.
  my $action = $request_body->{action};

  my $handler = CCNQ::AE::Run::attempt_run($function,$action,$request_body,$context);

  debug("No handler for function=$function, action=$action"),
  return unless $handler;

  # Only send a response if:
  # - one was provided (i.e. method is a valid local method), and
  # - the message we received was not already a response.
  # The first test is required since multiple local resources may get
  # the same message, but only one should reply (the one that implements
  # the requested action).
  my $send_response = sub {
    my $error  = $@;
    my $result = shift;

    debug("XMPPAgent: send_response got error=$error, result=$result");

    # CANCEL is either "die 'cancel'" or ->send('cancel').
    if($error eq 'cancel' || $result eq 'cancel') {
      debug("CANCEL for function=$function, action=$action");
      return;
    }

    # Note that the presence of {status} is what differentiates a
    # query/request from a response (since {result} is optional).

    # FAILURE is either "die ..." or ->send([$error_template,...]);
    # Note that both die($error_msg) and die([$error_template,...]) are
    # valid and supported. (The later uses Maketext-type templates.)
    # However {error} must always be an arrayref.

    # If ->send([$error]) was used, use that (in preference to what $@ might
    # have reported).
    $error = $result if $result && ref($result) eq 'ARRAY';
    if($error) {
      # Make sure the error is an arrayref;
      $error = [$error] if ref($error) ne 'ARRAY';
      debug("FAILURE for function=$function, action=$action");
      _send_im_message($context,$msg->from,{
        status    => STATUS_FAILED,
        from      => CCNQ::Install::host_name,
        activity  => $request_body->{activity},
        action    => $request_body->{action},
        error     => $error,
        response_at => time(),
      });
      return;
    }

    # SUCCESS is either ->send(undef), ->send('completed'), or ->send({ name => value }).
    if( $result && $result ne 'completed' && ref($result) ne 'HASH' ) {
      error(Carp::longmess("Coding error: $result is not a valid response"));
      return;
    }

    # Cleanup CouchDB extraneous data
    if(ref($result)) {
      delete $result->{_id};
      delete $result->{_rev};
    }

    debug("SUCCESS for function=$function, action=$action");
    my $response = {
      status    => STATUS_COMPLETED,
      from      => CCNQ::Install::host_name,
      activity  => $request_body->{activity},
      action    => $request_body->{action},
      response_at => time(),
    };
    # $result is either undef, 'completed' or a hashref.
    # Only report a valid content -- i.e. a hashref.
    $response->{result} = $result if ref($result);
    _send_im_message($context,$msg->from,$response);
    return;
  };

  # Run the handler.
  my $cv = eval { $handler->() };
  if($@) {
    $send_response->();
    return;
  }

  # No need to send a response if we did not get a callback.
  debug("CANCEL for function=$function, action=$action (no condvar)"),
  return unless $cv;

  $cv->cb(sub{
    $send_response->(eval { shift->recv });
  });

  return $cv;
}

sub _join_room {
  my ($context,$dest) = @_;
  my $nick = join(',',$context->{function},$context->{username},rand());
  info("Attempting to join $dest as $nick");
  $context->{muc}->join_room($context->{connection},$dest,$nick,{
    history => {seconds=>0},
    create_instant => 1,
  });
}

sub join_cluster_room {
  my ($context) = @_;
  my $muc_jid = CCNQ::Install::make_muc_jid($context->{cluster});
  _join_room($context,$muc_jid);
}

sub start {
  my ($cluster_name,$role,$function,$program) = @_;

  debug("($cluster_name,$role,$function) Starting XMPPAgent");

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
  my $resource = $function.'_'.$cluster_name;
  my $password = CCNQ::Install::make_password(CCNQ::Install::xmpp_tag);

  debug("($cluster_name,$role,$function) Creating XMPP Connection for ${username}\@${domain}/${resource} using password $password.");

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
    joined_muc  => {},
    pending_muc => {},
  };

  my $session_ready_sub = CCNQ::AE::Run::attempt_run($function,'_session_ready',{},$context);

  $con->reg_cb (

    # AnyEvent::XMPP::Connection
    error => sub {
      my $con = shift;
      my ($error) = @_;
      error("($cluster_name,$role,$function) xmpp error: " . $error->string);
      $program->end;
    },
    connect => sub {
      my $con = shift;
      my ($host,$port) = @_;
      debug("($cluster_name,$role,$function) Connected to ${host}:${port}");
    },
    disconnect => sub {
      my $con = shift;
      my ($host,$port,$message) = @_;
      error("($cluster_name,$role,$function) Disconnected from ${host}:${port}: ${message}");
      $program->end;
    },

    # AnyEvent::XMPP::IM::Connection
    session_ready => sub {
      my $con = shift;
      debug("($cluster_name,$role,$function) Connected as " . $con->jid . " in function $context->{function}");
      $con->send_presence("present");
      # my ($user, $host, $res) = split_jid ($con->jid);
      if($session_ready_sub) {
        my $cv = $session_ready_sub->();
        $program->cb($cv) if $cv;
      }
    },
    session_error => sub {
      my $con = shift;
      my ($error) = @_;
      error("($cluster_name,$role,$function) session_error: " . $error->string);
      $program->end;
    },
    presence_update => sub {
      my $con = shift;
      my ($roster, $contact, $old_presence, $new_presence)= @_;
      # debug('presence_update '.$contact->jid);
    },
    presence_error => sub {
      my $con = shift;
      my ($error) = @_;
      error("($cluster_name,$role,$function) presence_error: " . $error->string);
    },
    message => sub {
      my $con = shift;
      my ($msg) = @_;
      debug("($cluster_name,$role,$function) " . $context->{username}.'/'.$context->{resource}.": IM Message from: " . $msg->from . "; body: " . $msg->any_body);
      my $cv = handle_message($context,$msg);
      $program->cb($cv) if $cv;
    },
    message_error => sub {
      my $con = shift;
      my ($error) = @_;
      error("($cluster_name,$role,$function) message_error: " . $error->string);
    },

    # PubSub-specific
    pubsub_recv => sub {
      my ($con) = @_;
      debug("($cluster_name,$role,$function) pubsub_recv");
    },

  );

  $muc->reg_cb (
    # AnyEvent::XMPP::Ext::MUC
    # Can't register enter and join_error because join_room() already does
    # (and breaks if we try to).
    enter => sub {
      my $muc = shift;
      my ($room,$user) = @_;
      debug("($cluster_name,$role,$function) ".$user->nick . " (me) entered ".$room->jid);
      _joined_muc($context,$room->jid);
    },
    leave => sub {
      my $muc = shift;
      my ($room,$user) = @_;
      debug("($cluster_name,$role,$function) ".$user->nick . " (me) left ".$room->jid);
      _left_muc($context,$room->jid);
    },
    presence => sub {
      my $muc = shift;
      my ($room,$user) = @_;
      debug("($cluster_name,$role,$function) presence");
    },
    join => sub {
      my $muc = shift;
      my ($room,$user) = @_;
      debug("($cluster_name,$role,$function) ".$user->nick . " joined ".$room->jid);
    },
    part => sub {
      my $muc = shift;
      my ($room,$user) = @_;
      debug("($cluster_name,$role,$function) ".$user->nick . " left ".$room->jid);
    },
    message => sub {
      my $muc = shift;
      my ($room,$msg,$is_echo) = @_;
      debug("($cluster_name,$role,$function) ".$context->{username}.'/'.$context->{resource}.": in room: " . $room->jid . ", MUC message from: " . $msg->from . "; body: " . $msg->any_body);
      # my ($user, $host, $res) = split_jid ($msg->to);
      my $cv = handle_message($context,$msg);
      $program->cb($cv) if $cv;
    },
  );

  info("($cluster_name,$role,$function) Connecting");
  $con->connect ();
}

1;

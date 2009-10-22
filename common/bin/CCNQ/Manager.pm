package CCNQ::Manager;

use CCNQ::Install;
use File::Spec;

use constant manager_db => 'manager';
use constant manager_requests_dir => File::Spec->catfile(CCNQ::Install::SRC,qw( manager requests ));

sub request_to_activity {
  my ($request_type) = @_;
  my $request_file = File::Spec->catfile(manager_requests_dir,"${request_type}.pm");
  if( -e $request_file ) {
    my $eval = CCNQ::Install::content_of($request_file);
    my $sub = eval($eval);
    if($@) {
      error("Request ${request_type} code is invalid: $@");
      return undef;
    }
    return $sub;
  } else {
    error("Request ${request_type} does not exist");
    return undef;
  }
}

sub activities_for_request {
  my ($request) = @_;
  my @result = ();
  if($request->{action}) {
    my $sub = request_to_activity($request->{action});
    if($sub) {
      return $sub->($request);
    } else {
      $request->{status} = 'Unknown request';
    }
  } else {
    $request->{status} = 'No action specified';
  }
}

sub submit_activity {
  my ($context,$activity) = @_;

  my $msg = encode_json($activity);

  # Forward the activity to the proper MUC
  if($activity->{cluster_name}) {
    my $room = $muc->get_room ($context->{connection}, $activity->{cluster_name});
    if($room) {
      my $immsg = $room->make_message(body => $msg);
      $immsg->send();
      $activity->{submitted} = time;
    } else {
      warning("$activity->{cluster_name}: Not joined yet");
    }
  } elsif($activity->{node_name}) {
    my $dest = $activity->{node_name};
    my $immsg = new AnyEvent::XMPP::IM::Message(to => $dest, body => $msg);
    $immsg->send($context->{connection});
    $activity->{submitted} = time;
  }
}

1;
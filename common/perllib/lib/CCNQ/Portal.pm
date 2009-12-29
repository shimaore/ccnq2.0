package CCNQ::Portal;
use strict; use warnings;
use base CCNQ::Object;

sub current_session {
  my $self = shift;
  return $self->{_session} ||= new CCNQ::Portal::Session($cgi,$user,$site);
}

sub current_user {
  my $self = shift;
  if($self->current_session) {
    return $self->current_session->user;
  } else {
    return undef;
  }
}

sub current_language {
  my $self = shift;
  if($self->current_session) {
    return $self->current_session->current_language;
  } else {
    return undef;
  }
}

1;

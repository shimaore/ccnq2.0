package CCNQ::Portal;




sub current_user {
  my $self = shift;
  if($self->current_session) {
    return $self->current_session->user;
  } else {
    return undef;
  }
}

1;
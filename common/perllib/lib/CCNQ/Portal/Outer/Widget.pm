package CCNQ::Portal::Outer::Widget;

use base CCNQ::Object;

=pod

  new CCNQ::Portal::Outer::Widget $session

=cut

sub _init {
  my ($self,$session) = @_;
  $self->{_session} = $session;
}

sub session { return $_[0]->{_session} }

sub _in {
  ...
  
  my $untainter = CGI::Untaint->new($receiver->Vars);
  my $response = $self->in($untainter);
  return q(<div class="error">).$response->[1].q(</div>) unless $response->[0] eq 'ok';
  return $self->out(...);
}

=pod

  in($untainter)

=cut

=pod

  out($...)

=cut

1;

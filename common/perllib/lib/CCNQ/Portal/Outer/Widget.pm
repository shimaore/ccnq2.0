package CCNQ::Portal::Outer::Widget;

sub if_ok {
  my ($response,$cb) = @_;
  return throw_error($response) || $cb->($response->[1]);
}

sub throw_error {
  my ($response) = @_;
  return undef if $response->[0] eq 'ok';
  return q(<div class="error">).$response->[1].q(</div>);
}

=pod
sub _in {
  ...
  
  my $untainter = CGI::Untaint->new($receiver->Vars);
  my $response = $self->in($untainter);
}
=cut

1;

package Rating::Process;


sub process {
  my ($fh,$cb) = @_;
  my $headers = <$fh>;
  chomp $headers;
  my @headers = split(/\t/,$headers);
  my $w = new AnyEvent->io( fh => $fh, poll => 'r', cb => sub {
    my $input = <$fh>;
    return undef $w if !defined $input;
    chomp $input;
    my @input = split(/\t/,$input);
    my $data;
    @$data{@headers} = @input;
    $cb->($data);
  });
}

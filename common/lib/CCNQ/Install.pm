package CCNQ::Install;

sub _execute {
  my $command = join(' ',@_);
  my $ret = system(@_);
  return 1 if $ret == 0;
  # Happily lifted from perlfunc.
  if ($? == -1) {
      print STDERR "Failed to execute ${command}: $!\n";
  }
  elsif ($? & 127) {
      printf STDERR "Child command ${command} died with signal %d, %s coredump\n",
          ($? & 127),  ($? & 128) ? 'with' : 'without';
  }
  else {
      printf STDERR "Child command ${command} exited with value %d\n", $? >> 8;
  }
  return 0;
}

sub first_line_of {
  open(my $fh, '<', $_[0]) or die "$_[0]: $!";
  my $result = <$fh>;
  chomp($result);
  close($fh) or die "$_[0]: $!";
  return $result;
}

sub print_to {
  open(my $fh, '>', $_[0]) or die "$_[0]: $!";
  print $fh $_[1];
  close($fh) or die "$_[0]: $!";
}

sub get_variable {
  my ($what,$file,$guess) = @_;
  my $result;
  if(-e $file) {
    $result = first_line_of($file);
    print "Using existing $what $result .\n";
  } else {
    print "Found $guess, please edit $file if needed.\n";
    print_to($file,$guess);
    exit(1);
  }
  return $result;
}

sub run_module {
  my 
  my $eval = ""
}
my $eval = "use lib '/var/www'; use CCNQ::Proxy::$class; \$c = new CCNQ::Proxy::$class (\$cgi,\$db,\$configuration::sip_challenge)";


1;
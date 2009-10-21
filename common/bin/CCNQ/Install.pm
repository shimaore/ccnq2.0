package CCNQ::Install;

# Where the local configuration information is kept.
use constant CCN => q(/etc/ccn);


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
  open(my $fh, '<', $_[0]) or croak "$_[0]: $!";
  my $result = <$fh>;
  chomp($result);
  close($fh) or croak "$_[0]: $!";
  return $result;
}

sub content_of {
  open(my $fh, '<', $_[0]) or croak "$_[0]: $!";
  local $/;
  my $result = <$fh>;
  close($fh) or croak "$_[0]: $!";
  return $result;
}

sub print_to {
  open(my $fh, '>', $_[0]) or croak "$_[0]: $!";
  print $fh $_[1];
  close($fh) or croak "$_[0]: $!";
}

sub get_variable {
  my ($what,$file,$guess) = @_;
  my $result;
  if(-e $file) {
    $result = first_line_of($file);
    print "Using existing $what $result .\n";
  } else {
    print "Found $what $guess, please edit $file if needed.\n";
    print_to($file,$guess);
    exit(1);
  }
  return $result;
}

# Source path resolution

use File::Spec;

use constant source_path => 'source_path';

# SRC: where the copy of the original code lies.
# I create mine in ~/src using:
#    cd $HOME/src && git clone git://github.com/stephanealnet/ccnq2.0.git

# Try to guess the source location from the value of $0.
sub container_path {
  my $abs_path = File::Spec->rel2abs($0);
  my ($volume,$directories,$file) = File::Spec->splitpath($abs_path);
  my @directories = File::Spec->splitdir($directories);
  pop @directories; # Remove bin/
  pop @directories; # Remove common/
  $directories = File::Spec->catdir(@directories);
  return File::Spec->catpath($volume,$directories,'');
}

use constant SRC_DEFAULT => container_path;

use constant _source_path_file => File::Spec->catfile(CCN,source_path);
use constant SRC => get_variable(source_path,_source_path_file,SRC_DEFAULT);

1;
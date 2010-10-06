package CCNQ::B2BUA::Process;
# Copyright (C) 2010  Stephane Alnet
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

# This script will locate all CDR files created since the last run,
# process them (sending them to the cdr server), then move the processed
# files away.

use CCNQ::Util;
use CCNQ::B2BUA;
use CCNQ::Rating::Process;
use CCNQ::Billing::Rating;
use CCNQ::Install;

use AnyEvent;
use CCNQ::AE;

# Debian's location
# Note: pre-1.0.6 this was in /opt/freeswitch/log/freeswitch.pid.
use constant FREESWITCH_PID_FILE => '/opt/freeswitch/run/freeswitch.pid';

# Tell freeswitch to rotate its CDR file
# Note: if FreeSwitch has not processed any call since it was restarted
#       the CDR file will not get rotated (even though it might not be
#       empty).
sub rotate_cdr {
  my $pid = CCNQ::Util::content_of(FREESWITCH_PID_FILE) or die $!;
  kill(1, $pid) or die $!;
}

# Create the stowaway directory if it does not exist.
use constant PROCESSED_DIR => CCNQ::B2BUA::cdr_dir.'/processed';
use constant REJECTED_DIR  => CCNQ::B2BUA::cdr_dir.'/rejected';

sub stow_away {
  my ($file_name) = @_;
  my $cdr_file       = CCNQ::B2BUA::cdr_dir .'/'.$file_name;
  my $processed_file = PROCESSED_DIR        .'/'.$file_name;

  -d PROCESSED_DIR or mkdir PROCESSED_DIR;

  rename( $cdr_file, $processed_file  ) or die "$file_name: $!";
}

# Read the CDR directory entries.
sub read_entries {
  opendir(my $dh, CCNQ::B2BUA::cdr_dir) or die;
  my @entries = grep { /^Master\.csv\./ } readdir($dh);
  closedir($dh) or die;
  undef $dh;
  return @entries
}

# Process each CDR file.

use Logger::Syslog;

sub read_b2bua {
  my ($fh,$eh,$cb) = @_;
  my $line = 0;
  while(1) {
    my $input = <$fh>;
    return if !defined($input);
    chomp($input);
    $line++;
    debug("At line $line") if $line % 1000 == 0;
    my %f = map { /^(\w+)=(.*)$/; $1 => $2 }
            split(/\t/,$input);
    my $doc = $cb->(\%f);
    if(!$doc) {
      print $eh "$input\n";
    }
  }
}

sub process_file {
  my ($fh,$eh,$do_rating) = @_;

  my $rating_errors = 0;
  my $rate_and_save_flat_cbef = sub {
    my ($flat_cbef) = @_;
    if($flat_cbef->{start} =~ /^(\d{4}-\d{2}-\d{2}) (\d{2}:\d{2}:\d{2})$/) {
      $flat_cbef->{start_date} = $1; $flat_cbef->{start_time} = $2;
      $flat_cbef->{start_date} =~ s/[^\d]//g;
      $flat_cbef->{start_time} =~ s/[^\d]//g;
    } else {
      debug("Invalid start timestamp: ".$flat_cbef->{start});
      return;
    }
    my $cv;
    if($do_rating) {
      $cv = CCNQ::Billing::Rating::rate_and_save_cbef({
        %$flat_cbef,
        collecting_node => CCNQ::Install::host_name,
      });
    } else {
      $cv = CCNQ::Billing::Rating::save_cbef({
        %$flat_cbef,
        collecting_node => CCNQ::Install::host_name,
      });
    }
    my $doc = CCNQ::AE::receive($cv);
    return $doc;
  };

  read_b2bua($fh,$eh,$rate_and_save_flat_cbef);
}

sub run {
  my ($do_rating) = @_;
  rotate_cdr();

  my @entries = read_entries();

  -d REJECTED_DIR or mkdir REJECTED_DIR;

  for my $file (sort @entries) {
    my $full_name = CCNQ::B2BUA::cdr_dir.'/'.$file;
    my $rejected  = REJECTED_DIR.'/'.$file;
    open(my $fh, '<', $full_name) or die "$full_name: $!";
    open(my $eh, '>', $rejected ) or die "$rejected: $!";
    my $ok = process_file($fh,$eh,$do_rating);
    close($eh) or die "$rejected: $!";
    close($fh) or die "$full_name: $!";
    stow_away($file);
  }
}

'CCNQ::B2BUA::Process';

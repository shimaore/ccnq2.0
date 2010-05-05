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
use constant FREESWITCH_PID_FILE => '/opt/freeswitch/log/freeswitch.log';

# Tell freeswitch to rotate its CDR file
sub rotate_cdr {
  my $pid = CCNQ::Util::content_of(FREESWITCH_PID_FILE) or die $!;
  kill(1, $pid) or die $!;
}

# Create the stowaway directory if it does not exist.
use constant PROCESSED_DIR => CCNQ::B2BUA::cdr_dir.'/processed';

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

sub process_file {
  my ($fh) = @_;
  my $rcv = AE::cv;
  $rcv->begin;

  my $rating_errors = 0;
  my $rate_and_save_flat_cbef = sub {
    my ($flat_cbef) = @_;
    my $cv = CCNQ::Billing::Rating::rate_and_save_cbef({
      %$flat_cbef,
      collecting_node => CCNQ::Install::host_name,
    })->cb(sub{
      my $error = CCNQ::AE::receive(@_);
      if($error) {
        use Logger::Syslog;
        warning(CCNQ::AE::pp($error));
        $rating_errors++;
      }
    });
    CCNQ::AE::receive($cv);
  };

  my $w = CCNQ::Rating::Process::process($fh,$rate_and_save_flat_cbef,$rcv);
  my $result = CCNQ::AE::receive($rcv);
  return $rating_errors == 0;
}

sub run {
  my @entries = read_entries();

  for my $file (@entries) {
    my $full_name = CCNQ::B2BUA::cdr_dir.'/'.$file;
    open(my $fh, '<', $full_name) or die "$file: $!";
    my $ok = process_file($fh);
    close($fh) or die "$file: $!";
    stow_away($file) if $ok;
  }
}

'CCNQ::B2BUA::Process';

package CCNQ::B2BUA;
# Copyright (C) 2009  Stephane Alnet
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

use CCNQ;
use CCNQ::Util;
use File::Spec;
use File::Path;

use Logger::Syslog;

use constant::defer b2bua_directory =>
  sub { File::Spec->catfile(CCNQ::SRC,qw( b2bua )) };

use constant freeswitch_install_conf => '/opt/freeswitch/conf'; # Debian

use constant log_dir  => '/var/log/freeswitch';         # As specified in logfile.conf.xml
use constant cdr_dir  => log_dir.'/cdr-csv';            # As specified in cdr_csv.conf.xml

sub mk_dir {
  my $dst_dir = File::Spec->catfile(CCNQ::B2BUA::freeswitch_install_conf,@_);
  debug("Creating target directory $dst_dir");
  File::Path::mkpath([$dst_dir]);
}

sub finish {
  # Create the logs directory and change ownership
  File::Path::mkpath([CCNQ::B2BUA::log_dir]);
  CCNQ::Util::execute('chown','freeswitch.daemon',CCNQ::B2BUA::log_dir);
  # Create the CDR directory and change ownership
  File::Path::mkpath([CCNQ::B2BUA::cdr_dir]);
  CCNQ::Util::execute('chown','freeswitch.daemon',CCNQ::B2BUA::cdr_dir);

  # Change ownership of the configuration files
  CCNQ::Util::execute('chown','-R','freeswitch.daemon',freeswitch_install_conf);
}

sub install_dir {
  my $file_name = pop;
  mk_dir(@_);
  return File::Spec->catfile(CCNQ::B2BUA::freeswitch_install_conf,@_,$file_name);
}

sub install_file {
  my $cb = pop;
  my $function = shift;
  my @path = @_;
  my $src_dir = File::Spec->catfile(b2bua_directory,$function,qw( freeswitch conf ));
  my $src = File::Spec->catfile($src_dir,@path);
  my @dst_dir = (@path);
  pop @dst_dir;
  mk_dir(@dst_dir);
  my $dst = install_dir(@path);
  debug("Installing $src as $dst");
  my $txt = CCNQ::Util::content_of($src);
  return error("No file $src") if !defined($txt);
  $txt = $cb->($txt) if $cb;
  CCNQ::Util::print_to($dst,$txt);
}

sub copy_file {
  install_file(@_,undef);
}


1;
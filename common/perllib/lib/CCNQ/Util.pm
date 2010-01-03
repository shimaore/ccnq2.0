package CCNQ::Util;
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
use Logger::Syslog;
use Carp qw(croak);

=pod
  $text = first_line_of($filename)
    Returns the first line of the file $filename,
    or undef if an error occurred.
=cut

sub first_line_of {
  open(my $fh, '<', $_[0]) or error("$_[0]: $!"), return undef;
  my $result = <$fh>;
  chomp($result);
  close($fh) or error("$_[0]: $!"), return undef;
  return $result;
}

=pod
  $content = content_of($filename)
    Returns the content of file $filename,
    or undef if an error occurred.
=cut

sub content_of {
  open(my $fh, '<', $_[0]) or error("$_[0]: $!"), return undef;
  local $/;
  my $result = <$fh>;
  close($fh) or error("$_[0]: $!"), return undef;
  return $result;
}

=pod
  print_to($filename,$content)
    Saves the $content to the specified $filename.
    croak()s on errors.
=cut

sub print_to {
  open(my $fh, '>', $_[0]) or croak "$_[0]: $!";
  print $fh $_[1];
  close($fh) or croak "$_[0]: $!";
}

1;

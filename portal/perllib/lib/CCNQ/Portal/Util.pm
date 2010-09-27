package CCNQ::Portal::Util;
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

use Dancer ':syntax';
use Encode qw(:fallbacks);

=head2 neat(\$result,@fields)

Clean up (trim and utf8) parameters. Returns non-empty values in
a hashref.

=cut

sub neat {
  my $params = shift;
  for my $p (@_) {
    my $v = params->{$p};
    next unless defined $v;
    $v = Encode::decode_utf8($v,Encode::FB_HTMLCREF);
    next unless defined $v;
    $v =~ s/^\s+//; $v =~ s/\s+$//; $v =~ s/\s+/ /g;
    next if $v eq '';
    $params->{$p} = $v;
  }
  return $params;
}

=head1 strip

Same as neat() but explicitely set the value to undef instead of
not storing it.

=cut

sub strip {
  my $params = shift;
  for my $p (@_) {
    my $v = params->{$p};
    if(defined($v)) {
      $v = Encode::decode_utf8($v,Encode::FB_HTMLCREF);
    }
    if(defined($v)) {
      $v =~ s/^\s+//; $v =~ s/\s+$//; $v =~ s/\s+/ /g;
    }
    $v = undef if defined($v) && $v eq '';
    $params->{$p} = $v;
  }
  return $params;
}

sub redirect_request {
  my $r = CCNQ::AE::receive(@_);

  # Redirect to the request
  my $prefix = prefix;
  defined $prefix or $prefix = '';
  my $url = $prefix.'/request/'.$r->{request};
  return redirect $url;
}

use constant password_charset => "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-";
use constant password_charset_length => length(password_charset);

sub random_password {
  my ($length) = @_;
  return '' if $length == 0;
  return random_password($length-1).substr(password_charset,int(rand(password_charset_length)),1);
}

1;

package CCNQ::Portal::Outer::Widget;
# Copyright (C) 2009  Stephane Alnet
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation; either version 3
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
use strict; use warnings;
use base qw( Exporter );
use vars '@EXPORT_OK';
our @EXPORT_OK = qw( &if_ok );

use Dancer ':syntax';

sub if_ok {
  my ($response,$cb) = @_;
  return throw_error($response) || $cb->($response->[1]);
}

sub throw_error {
  my ($response) = @_;
  return undef if $response->[0] eq 'ok';
  var error => $response->[1];
  { error => $response->[1] };
}

=pod
sub _in {
  ...

  my $untainter = CGI::Untaint->new($receiver->Vars);
  my $response = $self->in($untainter);
}
=cut

'CCNQ::Portal::Outer::Widget';

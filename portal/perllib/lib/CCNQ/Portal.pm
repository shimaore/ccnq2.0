package CCNQ::Portal;
=head1 NAME
  Portal for ccnq2.0

=head1 AUTHOR
  Stephane Alnet <stephane@shimaore.net>

=head1 LICENSE
Copyright (C) 2009  Stephane Alnet

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 3
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

use 5.008;

our $VERSION = '0.02';

use strict; use warnings;

# XXX Need db install
use constant portal_db => 'portal';

# Must be set by the startup code.
our $site;

# e.g.   use CCNQ::Portal (CCNQ::Portal::Site->new( default_locale => 'en-US', security => new CCNQ::Portal::Auth::LDAP( ... ) )

sub import {
  my $self = shift;
  $site ||= shift;
}

sub site {
  return $site;
}


our $session;

sub current_session {
  my $self = shift;
  use CCNQ::Portal::Session;
  return $session ||= CCNQ::Portal::Session->new($self->site);
}

'CCNQ::Portal';

package CCNQ::CouchDB::CodeStore;
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

=head1 DESCRIPTION

This module provides a code store where a key is used to give access to a sub()
which code is stored in a CouchDB database.

The code is retrieved from the database the first time the key is requested.
The code is also re-retrieved if the key was last accessed a given amount of
time ago, allowing to refresh the keys when needed.
Optionally, the cache may also be flushed.

=cut

use constant CODESTORE_CACHE_DELAY => 60; # seconds

use AnyEvent;
use AnyEvent::CouchDB;
use CCNQ::AE;

sub new {
  my ($class,$db_uri,$db_name) = @_;
  $class = ref($class) || $class;
  my $self = {
    db    => couch($db_uri)->db($db_name),
    cache => {},
  };
  return bless $self, $class;
}

sub load_entry {
  my ($self,$key) = @_;
  my $cv = AE::cv;

  if( $self->{cache}->{$key} &&
      time() < $self->{cache}->{$key}->{timestamp} + CODESTORE_CACHE_DELAY )
  {
    $cv->send( $self->{cache}->{$key}->{code} );
    return $cv;
  }

  $self->{db}->open_doc($key)->cb(sub{
    my $doc = CCNQ::AE::receive(@_);

    unless( $doc && $doc->{_rev} && $doc->{code} ) {
      $self->{cache}->{$key} = {
        timestamp    => time(),
      };
      $cv->send;
      return;
    }

    if( !$self->{cache}->{$key} ||
        $self->{cache}->{$key}->{rev} ne $doc->{_rev} )
    {
      $self->{cache}->{$key} = {
        rev          => $doc->{_rev},
        timestamp    => time(),
        code         => eval($doc->{code}),
      };
      if($@) {
        $cv->send;
        return;
      }
    }
    $cv->send( $self->{cache}->{$key}->{code} );
  });
  return $cv;
}

sub flush_entry {
  my ($self,$key) = @_;
  delete $_[0]->{cache}->{$key};
}

'CCNQ::CouchDB::CodeStore';

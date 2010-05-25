package CCNQ::Rating::Bucket::DB;
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

use CCNQ::Install;

use AnyEvent;
use CCNQ::CouchDB;

use constant BUCKET_CLUSTER_NAME => 'bucket';

use constant::defer bucket_server => sub {
  CCNQ::Install::make_couchdb_uri_from_server(CCNQ::Install::cluster_fqdn(BUCKET_CLUSTER_NAME))
};
use constant bucket_db => 'bucket';

use constant bucket_designs => {
  report => {
    language => 'javascript',
    views    => {
    },
  },
};

sub install {
  my ($params,$context) = @_;
  return CCNQ::CouchDB::install(bucket_server,bucket_db,bucket_designs);
}

sub retrieve_bucket_instance {
  my ($id) = @_;
  return CCNQ::CouchDB::retrieve_cv(bucket_server,bucket_db,{ _id => $id });
}

use Scalar::Util qw(blessed);
use Data::Structure::Util qw(unbless);

sub cleanup {
  my $self = shift;

  if(!defined($self)) {
    return undef;
  }
  if(blessed($self) =~ /^Math::Big/) {
    return unbless($self->bstr());
  }
  if(UNIVERSAL::isa($self, "ARRAY")) {
    return [map { cleanup($_) } @{$self}];
  }
  if(UNIVERSAL::isa($self, "HASH")) {
    return { map { $_ => cleanup($self->{$_}) } keys %{$self} };
  }
  return "$self";
}

sub update_bucket_instance {
  my ($rec) = @_;
  return CCNQ::CouchDB::update_cv(bucket_server,bucket_db,cleanup($rec));
}

'CCNQ::Rating::Bucket::DB';

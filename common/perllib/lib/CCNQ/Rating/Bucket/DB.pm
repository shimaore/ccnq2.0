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

use constant bucket_db => 'http://'.CCNQ::Install::cluster_fdqn('bucket').'/bucket';

use constant cdr_designs => {
  report => {
    language => 'javascript',
    views    => {
    },
  },
};

sub install {
  my ($params,$context) = @_;
  return CCNQ::CouchDB::install(cdr_db,cdr_designs);
}

use constant BUCKET_NAME_PREFIX => 'bucket';

sub retrieve_bucket_instance {
  my ($key) = @_;
  my $id = join('/',BUCKET_NAME_PREFIX,$key);
  return CCNQ::CouchDB::retrieve_cv(cdr_db,$id);
}

sub save_bucket_instance {
  my ($rec) = @_;
  return CCNQ::CouchDB::update_cv(cdr_db,$rec);
}

'CCNQ::Rating::Bucket::DB';

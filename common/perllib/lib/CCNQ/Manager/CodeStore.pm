package CCNQ::Manager::CodeStore;
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

=head1 CCNQ::Manager::CodeStore

Used to update, delete, or retrieve Perl code which is stored on the manager
CouchDB database for dynamic (manager-side) request-to-activities mapping.
(Complements the mappings already offered under CCNQ::Manager::Requests::.)

=cut

use CCNQ::Manager;

use constant manager_codestore_designs => {};

use CCNQ::CouchDB;

sub install {
  return CCNQ::CouchDB::install(
    CCNQ::Manager::manager_uri,
    CCNQ::Manager::manager_codestore_db,
    manager_codestore_designs
  );
}

sub update {
  my ($params) = @_;
  return CCNQ::CouchDB::update_cv(
    CCNQ::Manager::manager_uri,
    CCNQ::Manager::manager_codestore_db,
    $params
  );
}

sub delete {
  my ($params) = @_;
  return CCNQ::CouchDB::delete_cv(
    CCNQ::Manager::manager_uri,
    CCNQ::Manager::manager_codestore_db,
    $params
  );
}

sub retrieve {
  my ($params) = @_;
  return CCNQ::CouchDB::retrieve_cv(
    CCNQ::Manager::manager_uri,
    CCNQ::Manager::manager_codestore_db,
    $params
  );
}

'CCNQ::Manager::CodeStore';

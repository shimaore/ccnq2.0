package CCNQ::Portal;
=head1 NAME
  Portal for ccnq2.0

=head1 AUTHOR
  Stephane Alnet <stephane@shimaore.net>

=head1 LICENSE
Copyright (C) 2009  Stephane Alnet

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU Affero General Public License
as published by the Free Software Foundation; either version 3
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

use 5.008;

our $VERSION = '0.055';

use strict; use warnings;

use File::ShareDir;
use constant CCNQ_PORTAL_MAKEFILE_MODULE_NAME => 'CCNQ-Portal';
use constant SRC => File::ShareDir::dist_dir(CCNQ_PORTAL_MAKEFILE_MODULE_NAME);

# CouchDB database
use constant::defer portal_uri => sub {
  use CCNQ::Install;
  CCNQ::Install::make_couchdb_uri_from_server(CCNQ::Install::cluster_fqdn('portal-db'))
};

use constant portal_db => 'portal';

use constant js_report_portal_users_by_account => <<'JAVASCRIPT';
  function(doc) {
    if(doc.portal_accounts) {
      for (var account in doc.portal_accounts) {
        emit([doc.portal_accounts[account]],null);
      }
    }
  }
JAVASCRIPT

use constant portal_designs => {
  report => {
    language => 'javascript',
    views    => {
      portal_users_by_account => {
        map => js_report_portal_users_by_account,
      },
    },
  },
};

sub install {
  use CCNQ::CouchDB;
  return CCNQ::CouchDB::install(portal_uri,portal_db,portal_designs);
}

sub db {
  use AnyEvent::CouchDB;
  return couch(portal_uri)->db(portal_db);
}

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

=head2 content()

Provides the default content for this portal's site.

=cut

sub content { site->default_content->(@_) }
sub normalize_number { site->normalize_number->(@_) }


our $session;

sub current_session {
  my $self = shift;
  use CCNQ::Portal::Session;
  return $session ||= CCNQ::Portal::Session->new($self->site);
}

'CCNQ::Portal';

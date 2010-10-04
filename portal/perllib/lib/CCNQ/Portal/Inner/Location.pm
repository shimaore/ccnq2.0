package CCNQ::Portal::Inner::Location;
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
use strict; use warnings; use Carp;

use Dancer ':syntax';
use CCNQ::Portal;
use CCNQ::Portal::I18N;
use CCNQ::Portal::Util;
use CCNQ::Portal::Inner::Util;

use CCNQ::AE;
use CCNQ::API;

=head1 Locations

Locations are stored in the provisioning database, the database which
is also used to store endpoints and numbers.

Locations are used primarily for the purpose of providing emergency location
information to the carrier responsible for routing emergency calls.

A location _id is an internal identifier used to uniquely identify a location
as created by an administrator or a customer. It is decoupled from the
information sent to the carrier, which generally will consist mostly of
the caller identifier (ANI) or a more generic location identifier (e.g. the
commune ID in France).

Numbers and endpoints can be mapped to locations. The number's location
is used preferentially; if it is not available, the endpoint's location is
used.

Besides the fields used to store the address or GPS coordinates, etc., the
following fields are common to all location records:

  _id       the (internal) location identifier
  account   the account that provisioned this location
  routing   the location routing data (e.g. "main number" or ERL in the US, commune ID in France)

=cut

sub get_location {
  CCNQ::Portal->current_session->user
    or return CCNQ::Portal::content( error => _('Unauthorized')_ );

  var get_location  => \&CCNQ::Portal::Inner::Util::get_location;
  var locations_for => \&CCNQ::Portal::Inner::Util::locations_for;

  return CCNQ::Portal::content;
}

sub clean_params {
  my $params = {
    account       =>   CCNQ::Portal::Inner::Util::validate_account,
  };

  CCNQ::Portal::Util::neat($params,qw(
    location
    name
    main_number
    routing_data

    address_1
    address_2
    city
    postal_code
    state
    country
  ));

  return $params;
};

'CCNQ::Portal::Inner::Location';

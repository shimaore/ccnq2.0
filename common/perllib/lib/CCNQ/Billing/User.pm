package CCNQ::Billing::User;
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

sub _user_id {
  return join('/','user',@_);
}

use CCNQ::Billing;

=head1 Content of a "user" record

user_profile

  _id: "user/${user_id}"
  profile: "user"

  name: $user_name
  email: $user_email
  billing_accounts: [ ${account_id}, .. ]

  Notes:
  "billing_accounts" lists the accounts which this portal user will
  receive invoices for.

  Other information such as access levels (portal_accounts, pricing
  access, which operations are available to which users, ..), passwords,
  etc. are managed directly by the portal front-end and are not stored
  in the "billing" database.

=cut

=head1 update_user({ user_id => $user_id, ... })

Returns a condvar.

=cut

sub update_user {
  my ($params) = @_;
  return CCNQ::Billing::billing_update({
    %$params,
    profile => 'user',
    _id     => _user_id($params->{user_id}),
  });
}

=head1 retrieve_user({ user_id => $user_id })

Returns a condvar which will return undef or a hashref describing an account.

=cut

sub retrieve_user {
  my ($params) = @_;
  return CCNQ::Billing::billing_retrieve({
    _id => _user_id($params->{user_id})
  });
}

'CCNQ::Billing::User';

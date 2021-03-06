package CCNQ::Portal::Inner::CDR;
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

use Dancer ':syntax';
use CCNQ::Portal;
use CCNQ::Portal::I18N;
use CCNQ::Portal::Util;
use CCNQ::Portal::Inner::Util;
use CCNQ::API;

use CCNQ::AE;

sub as_html {
  my $cv = shift;

  my $account = CCNQ::Portal::Inner::Util::validate_account;

  var template_name => 'api/cdr';
  CCNQ::Portal->current_session->user &&
  $account
    or return CCNQ::Portal::content;

  CCNQ::Portal::Inner::Util::user_can_access_billing_for($account)
    or return CCNQ::Portal::content( error => _('You are not authorized to view billing data for this account.')_ );

  var account_subs  => \&CCNQ::Portal::Inner::Util::account_subs;
  var event_types   => \&CCNQ::Portal::Inner::Util::event_types;

  $cv and var result => sub { CCNQ::AE::receive_docs($cv) };
  return CCNQ::Portal::content;
}

sub as_json {
  my $cv = shift;
  $cv or return send_error();
  content_type 'text/json';
  return to_json($cv->recv);
}

=head1 /cdr/view

=cut

sub _view_id {
  my $account = CCNQ::Portal::Inner::Util::validate_account;

  CCNQ::Portal::Inner::Util::user_can_access_billing_for($account)
    or return;

  # New model: CouchDB as API
  use CCNQ::CDR;
  return CCNQ::CDR::period($account,params->{year},params->{month},params->{day});
}

# View one
get '/cdr/query.html' => sub { as_html() };
get '/cdr/view.html'  => sub { as_html(_view_id) };
get '/cdr/view.json'  => sub { as_json(_view_id) };

'CCNQ::Portal::Inner::billing_plan';

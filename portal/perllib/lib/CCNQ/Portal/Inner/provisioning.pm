package CCNQ::Portal::Inner::provisioning;
# Copyright (C) 2009  Stephane Alnet
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

use Dancer ':syntax';
use CCNQ::Portal;
use CCNQ::Portal::I18N;
use CCNQ::API;

=head1 /provisioning/account

Display the known provisioning information about a given account.

=cut

get '/provisioning/account' => sub {
  return unless CCNQ::Portal->current_session->user;
  var template_name => 'provisioning';
  my $view = 'report/account';
  my $account = session('account');
  return unless defined $account;

  my $cv = AE::cv;
  CCNQ::API::provisioning_view($view,$account,$cv);
  var result => $cv->recv;
  return CCNQ::Portal->site->default_content->();
};

=head1 /provisioning/:view/@id

Generic Provisioning API query, restricted to administrative accounts.

=cut

get '/provisioning/:view/*' => sub {
  return unless CCNQ::Portal->current_session->user;
  # Restrict the generic view to administrators
  return unless CCNQ::Portal->current_session->user->profile->is_admin;

  var template_name => 'provisioning';
  my $view = 'report/'.params->{view};
  my $id = splat;
  unshift @$id, session('account');

  my $cv = AE::cv;
  CCNQ::API::provisioning_view($view,$id,$cv);
  var result => $cv->recv;
  return CCNQ::Portal->site->default_content->();
};

'CCNQ::Portal::Inner::billing_plan';

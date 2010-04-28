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

=head1 /provisioning/:view/@id

Generic Provisioning API query, restricted to administrative accounts.

=cut

get '/provisioning/:view/:id' => sub {
  return unless CCNQ::Portal->current_session->user;
  return unless session('account');
  # Restrict the generic view to administrators
  return unless CCNQ::Portal->current_session->user->profile->is_admin;

  var template_name => 'provisioning';
  my ($id) = [params->{id}];
  unshift @$id, session('account');

  my $cv = AE::cv;
  CCNQ::API::provisioning_view('report',params->{view},@$id,$cv);
  var result => $cv->recv;
  return CCNQ::Portal->site->default_content->();
};

get '/provisioning/account' => sub {
  return unless CCNQ::Portal->current_session->user;
  return unless session('account');

  var template_name => 'provisioning';
  my $id = [session('account')];

  my $cv = AE::cv;
  CCNQ::API::provisioning_view('report','account',@$id,$cv);
  var result => $cv->recv;
  return CCNQ::Portal->site->default_content->();
};

'CCNQ::Portal::Inner::billing_plan';

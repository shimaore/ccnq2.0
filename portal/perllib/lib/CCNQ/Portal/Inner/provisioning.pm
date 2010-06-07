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

# View one
get '/provisioning/view/:view/:id' => sub {
  var template_name => 'provisioning';
  return CCNQ::Portal::content unless CCNQ::Portal->current_session->user;
  return CCNQ::Portal::content unless session('account');
  # Restrict the generic view to administrators
  return CCNQ::Portal::content unless CCNQ::Portal->current_session->user->profile->is_admin;

  my $account = session('account');
  my $id = params->{id};

  my $cv = AE::cv;
  if($id eq '_all') {
    CCNQ::API::provisioning('report',params->{view},$account,$cv);
  } else {
    CCNQ::API::provisioning('report',params->{view},$account,$id,$cv);
  }
  var result => $cv->recv;
  return CCNQ::Portal::content;
};

sub get_number {
  var template_name => 'provisioning';
  return CCNQ::Portal::content unless CCNQ::Portal->current_session->user;
  # Restrict the generic view to administrators
  return CCNQ::Portal::content unless CCNQ::Portal->current_session->user->profile->is_admin;

  my $number = params->{number};
  $number =~ s/\d+//g;

  my $cv = AE::cv;
  CCNQ::API::provisioning('report','all_numbers',$number,$cv);
  var result => $cv->recv;
  return CCNQ::Portal::content;
}

get '/provisioning/number'         => get_number;
get '/provisioning/number/:number' => get_number;

get '/provisioning/view/account' => sub {
  var template_name => 'provisioning';
  return CCNQ::Portal::content unless CCNQ::Portal->current_session->user;
  return CCNQ::Portal::content unless session('account');

  my $account = session('account');

  my $cv = AE::cv;
  CCNQ::API::provisioning('report','account',$account,$cv);
  var result => $cv->recv;
  return CCNQ::Portal::content;
};

'CCNQ::Portal::Inner::billing_plan';

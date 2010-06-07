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

sub to_html {
  my $cv = shift;
  var template_name => 'provisioning';
  $cv and var result => sub { $cv->recv };
  return CCNQ::Portal::content;
}

sub as_json {
  my $cv = shift;
  $cv or send_error();
  content_type 'text/json';
  return to_json($cv->recv);
}

=head1 /provisioning/:view/@id

Generic Provisioning API query, restricted to administrative accounts.

=cut

sub _view_id {
  CCNQ::Portal->current_session->user &&
  session('account') &&
  # Restrict the generic view to administrators
  CCNQ::Portal->current_session->user->profile->is_admin
    or return;

  my $account = session('account');
  my $id = params->{id};

  my $cv = AE::cv;
  if($id eq '_all') {
    CCNQ::API::provisioning('report',params->{view},$account,$cv);
  } else {
    CCNQ::API::provisioning('report',params->{view},$account,$id,$cv);
  }
  return $cv;
}

# View one
get      '/provisioning/view/:view/:id' => sub { to_html(_view_id) };
get '/json/provisioning/view/:view/:id' => sub { as_json(_view_id) };

sub _get_number {
  CCNQ::Portal->current_session->user &&
  CCNQ::Portal->current_session->user->profile->is_admin
    or return;

  my $cv = AE::cv;
  my $number = params->{number};
  if($number eq '_all') {
    CCNQ::API::provisioning('report','all_numbers',$cv);
  } else {
    $number =~ s/[^\d]+//g;
    CCNQ::API::provisioning('report','all_numbers',$number,$cv);
  }
  return $cv;
}

get      '/provisioning/number'         => sub { to_html(_get_number) };
get      '/provisioning/number/:number' => sub { to_html(_get_number) };
get '/json/provisioning/number'         => sub { as_json(_get_number) };
get '/json/provisioning/number/:number' => sub { as_json(_get_number) };

sub _view_account {
  CCNQ::Portal->current_session->user &&
  session('account')
    or return;

  my $account = session('account');

  my $cv = AE::cv;
  CCNQ::API::provisioning('report','account',$account,$cv);
  return $cv;
}

get      '/provisioning/view/account' => sub { to_html(_view_account) };
get '/json/provisioning/view/account' => sub { as_json(_view_account) };

'CCNQ::Portal::Inner::billing_plan';

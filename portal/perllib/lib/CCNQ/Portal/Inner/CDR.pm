package CCNQ::Portal::Inner::CDR;
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

use CCNQ::Portal::Inner::Util;

sub as_html {
  my $cv = shift;

  var template_name => 'api/cdr';
  CCNQ::Portal->current_session->user &&
  session('account')
    or return CCNQ::Portal::content;

  var account_subs  => \&CCNQ::Portal::Inner::Util::account_subs;
  var event_types   => \&CCNQ::Portal::Inner::Util::event_types;

  $cv and var result => sub { $cv->recv };
  return CCNQ::Portal::content;
}

sub as_json {
  my $cv = shift;
  $cv or return send_error();
  content_type 'text/json';
  return to_json($cv->recv);
}

=head1 /cdr/:view

=cut

sub _view_id {
  my $day   = params->{day};
  my @date = ();
  $day and push @date, $day;

  my $cv = AE::cv;
  CCNQ::API::cdr(
    'report',params->{view},
    session('account'),
    params->{account_sub},
    params->{event_type},
    params->{year},
    params->{month},
    @date,
    $cv);
  return $cv;
}

# View one
get      '/cdr/'      => sub { as_html() };
get      '/cdr/:view' => sub { as_html(_view_id) };
get '/json/cdr/:view' => sub { as_json(_view_id) };

'CCNQ::Portal::Inner::billing_plan';

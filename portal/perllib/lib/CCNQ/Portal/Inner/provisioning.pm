package CCNQ::Portal::Inner::provisioning;
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

=head1 Formatters

=head2 to_html

=head2 as_json

=head2 as_tabs

=cut

use constant hidden_columns => qr/^_|^account|^action|^api|^cluster|^request|^type|^endpoint_ip|^profile/;

sub to_html {
  my $cv = shift;
  var template_name => 'provisioning';
  $cv and var result => sub { CCNQ::AE::receive_docs($cv) };
  return CCNQ::Portal::content;
}

sub as_json {
  my $cv = shift;
  $cv or return send_error();
  content_type 'text/json';
  header 'Content-Disposition' => qq(attachment; filename="export.json");
  return to_json($cv->recv);
}

sub as_tabs {
  my $cv = shift;
  $cv or return send_error();
  content_type 'text/tab-separated-values';
  header 'Content-Disposition' => qq(attachment; filename="export.csv");
  my $result = CCNQ::AE::receive_docs($cv);
  $result->[0] or return "";
  my @columns = sort grep { !hidden_columns } keys %{ $result->[0] };
  unshift @columns, $result->[0]->{profile};
  return
    # header row
    join("\t", map { _($_)_ } @columns)."\n".
    # data rows
    join('', map {
      join("\t", map { defined($_) ? $_ : '' } @{$_}{@columns})."\n"  # everybody love hashref slices!
    } @$result);
}

=head1 /provisioning/view/:view/@id

Retrieve a view for the current (session) account.

=cut

sub _view_id {
  my $account = CCNQ::Portal::Inner::Util::validate_account;

  CCNQ::Portal->current_session->user &&
  $account
    or return;

  my $id = params->{id};

  my $cv = AE::cv;
  if($id eq '_all') {
    CCNQ::API::provisioning('report',params->{view},$account,$cv);
  } else {
    CCNQ::API::provisioning('report',params->{view},$account,$id,$cv);
  }
  return $cv;
}

get '/provisioning/view/:view/:id.html' => sub { to_html(_view_id) };
get '/provisioning/view/:view/:id.json' => sub { as_json(_view_id) };
get '/provisioning/view/:view/:id.tabs' => sub { as_tabs(_view_id) };

get '/provisioning/page/:view.html' => sub {
  CCNQ::Portal::Inner::Util::validate_account;

  my $page = int(params->{page} || 1);
  return paginate_html($page,_view_page($page));
};

use constant default_limit => 25;

sub paginate_html {
  my ($page,$cv) = @_;
  $cv or return send_error();

  my $limit = int(params->{limit} || default_limit);

  var page   => $page;
  var limit  => $limit;
  var result => sub { CCNQ::AE::receive_docs($cv) };

  var template_name => 'provisioning-paginate';
  return CCNQ::Portal::content;
}

sub _view_page {
  my $page = shift;
  my $limit = params->{limit} || default_limit;

  my $account = CCNQ::Portal::Inner::Util::validate_account;

  CCNQ::Portal->current_session->user &&
  $account
    or return;

  # New model: CouchDB as API
  use CCNQ::Provisioning;
  return CCNQ::Provisioning::provisioning_paginate(
    'report/'.params->{view},
    $account,
    ($page-1)*$limit,
    $limit,
  );
}

=head1 /provisioning/view/account

Retrieve all provisioning data for the current (session) account.

=cut

sub _view_account {
  my $account = CCNQ::Portal::Inner::Util::validate_account;

  CCNQ::Portal->current_session->user &&
  $account
    or return;

  my $cv = AE::cv;
  CCNQ::API::provisioning('report','account',$account,$cv);
  return $cv;
}

get '/provisioning/view/account.html' => sub { to_html(_view_account) };
get '/provisioning/view/account.json' => sub { as_json(_view_account) };
get '/provisioning/view/account.tabs' => sub { as_tabs(_view_account) };

=head1 /provisioning/lookup/:what

Lookup one item in the current account, or all accounts if admin.

=cut

sub _lookup {
  my $what = shift;

  return sub {
    CCNQ::Portal->current_session->user
      or return;

    my $params = {};
    CCNQ::Portal::Util::neat($params,qw(
      key
    ));

    my $key = $params->{key};
    $what eq 'number'
      and $key = CCNQ::Portal::normalize_number($key);
    defined($key)
      or return;

    if(CCNQ::Portal->current_session->user->profile->is_admin) {
      my $cv = AE::cv;
      if($key eq '_all') {
        CCNQ::API::provisioning('report',"lookup_${what}",$cv);
      } else {
        CCNQ::API::provisioning('report',"lookup_${what}",$key,$cv);
      }
      return $cv;
    }

    my $account = CCNQ::Portal::Inner::Util::validate_account;
    if($account) {
      my $cv = AE::cv;
      CCNQ::API::provisioning('report',"lookup_${what}_in_account",$account,$key,$cv);
      return $cv;
    }
    return;
  };
}

get '/provisioning/lookup/:what.html' => sub { to_html(_lookup(params->{what})->()) };
get '/provisioning/lookup/:what.json' => sub { as_json(_lookup(params->{what})->()) };
get '/provisioning/lookup/:what.tabs' => sub { as_tabs(_lookup(params->{what})->()) };

1;

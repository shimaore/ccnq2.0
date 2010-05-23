package CCNQ::Portal::Inner::RatingTable;
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
use utf8;

use Dancer ':syntax';
use CCNQ::Portal;
use CCNQ::Portal::I18N;
use CCNQ::Portal::Util;

use CCNQ::AE;
use CCNQ::API;

# ******* Utilities ***********

sub gather_fields {
  return [qw(
    country us_state
    count_cost
    duration_rate
    initial_duration increment_duration
    jurisdiction rate
  )];
}

sub gather_ratingtables {
  my $cv = AE::cv;
  CCNQ::API::rating_table($cv);
  my $tables = CCNQ::AE::receive($cv);
  return $tables;
}

sub gather_prefixes {
  my $cv = AE::cv;
  my $table_name = session('rating_table');
  return [] if not defined $table_name;
  CCNQ::API::rating_table($table_name,$cv);
  my $docs = CCNQ::AE::receive_docs($cv);
  return $docs;
}

sub gather_prefix {
  my ($table_name,$prefix) = @_;

  # Get the information from the API.
  my $prefix_data;
  if(defined $prefix) {
    my $cv2 = AE::cv;
    CCNQ::API::rating_table($table_name,$prefix,$cv2);
    $prefix_data = CCNQ::AE::receive_first_doc($cv2) || {};
  }
}

# ******* Rating-table selection ***********

sub set_rating_table {
  return CCNQ::Portal::content unless CCNQ::Portal->current_session->user and CCNQ::Portal->current_session->user->profile->is_admin;

  my $params = CCNQ::Portal::Util::neat({}, qw( rating_table ));

  if(defined $params->{rating_table}) {
    session rating_table => $params->{rating_table};
    var template_name => 'api/rating_table/edit';
    var rating_table_prefixes => \&gather_prefixes;
    var rating_table_fields => \&gather_fields;
    return CCNQ::Portal::content;
  } else {
    var template_name => 'api/rating_table/select';
    var rating_tables => \&gather_ratingtables;
    return CCNQ::Portal::content;
  }
}

sub new_rating_table {
  return CCNQ::Portal::content unless CCNQ::Portal->current_session->user and CCNQ::Portal->current_session->user->profile->is_admin;

  my $params = CCNQ::Portal::Util::neat({}, qw( rating_table ));

  if(defined $params->{rating_table}) {
    my $cv = AE::cv;
    CCNQ::API::api_update('table',{ name => $params->{rating_table} },$cv);
    my $r = CCNQ::AE::receive($cv);
    session rating_table => $params->{rating_table};
    redirect '/request/'.$r->{request};
  } else {
    var template_name => 'api/rating_table/new';
    return CCNQ::Portal::content;
  }
}

get  '/rating_table/' => \&set_rating_table;
post '/rating_table/' => \&set_rating_table;
get  '/rating_table/new' => \&new_rating_table;
post '/rating_table/new' => \&new_rating_table;

# ******* Content update ***********

sub modify_field {
  return CCNQ::Portal::content unless CCNQ::Portal->current_session->user and CCNQ::Portal->current_session->user->profile->is_admin;

  my $params = CCNQ::Portal::Util::neat({
    rating_table => session('rating_table'),
  }, qw(
    prefix field value
  ));

  # Empty prefix is OK.
  $params->{prefix} = '' if not defined $params->{prefix};

  var template_name => 'api/rating_table/edit';
  var rating_table_prefixes => \&gather_prefixes;
  var rating_table_fields => \&gather_fields;
  return CCNQ::Portal::content unless( defined($params->{field}) );

  my $cv = AE::cv;
  CCNQ::API::api_update('table_prefix',{ name => $params->{rating_table}, prefix => $params->{prefix}, $params->{field} => $params->{value} },$cv);
  my $r = CCNQ::AE::receive($cv);

  # Redirect to the request
  # redirect '/request/'.$r->{request};
  return CCNQ::Portal::content;
}

sub new_prefix {
  return CCNQ::Portal::content unless CCNQ::Portal->current_session->user and CCNQ::Portal->current_session->user->profile->is_admin;

  my $params = CCNQ::Portal::Util::neat({
    rating_table => session('rating_table'),
  }, qw(
    prefix
  ));

  # Empty prefix is OK.
  $params->{prefix} = '' if not defined $params->{prefix};

  var template_name => 'api/rating_table/edit';
  var rating_table_prefixes => \&gather_prefixes;
  var rating_table_fields => \&gather_fields;

  my $cv = AE::cv;
  CCNQ::API::api_update('table_prefix',{ name => $params->{rating_table}, prefix => $params->{prefix} },$cv);
  my $r = CCNQ::AE::receive($cv);

  # Redirect to the request
  # redirect '/request/'.$r->{request};
  return CCNQ::Portal::content;
}

post '/rating_table/modify_field' => \&modify_field;
post '/rating_table/new_field'    => \&modify_field;

post '/rating_table/new_prefix'   => \&new_prefix;

'CCNQ::Portal::Inner::RatingTable';

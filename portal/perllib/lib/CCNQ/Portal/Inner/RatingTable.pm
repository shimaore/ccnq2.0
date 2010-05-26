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
    country us_state city
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
  my $ids = CCNQ::AE::receive_ids($cv);
  return $ids;
}

sub gather_prefix {
  my ($prefix) = @_;

  my $table_name = session('rating_table');
  return if not defined $table_name or not defined $prefix;

  # Get the information from the API.
  my $cv2 = AE::cv;
  CCNQ::API::rating_table($table_name,$prefix,$cv2);
  my $prefix_data = CCNQ::AE::receive($cv2);
  return $prefix_data;
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
    var rating_table_prefix => \&gather_prefix;
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
    session rating_table => $params->{rating_table};
    return CCNQ::Portal::Util::redirect_request($cv);
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
  var rating_table_prefix => \&gather_prefix;
  return CCNQ::Portal::content unless( defined($params->{field}) );

  my $fields = gather_prefix($params->{prefix}) || {};
  $fields->{name}   = $params->{rating_table};
  $fields->{prefix} = $params->{prefix};
  $fields->{$params->{field}} = $params->{value};

  my $cv = AE::cv;
  CCNQ::API::api_update('table_prefix',$fields,$cv);
  my $r = CCNQ::AE::receive($cv);

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
  var rating_table_prefix => \&gather_prefix;

  my $cv = AE::cv;
  CCNQ::API::api_update('table_prefix',{ name => $params->{rating_table}, prefix => $params->{prefix} },$cv);
  my $r = CCNQ::AE::receive($cv);

  return CCNQ::Portal::content;
}

post '/rating_table/modify_field' => \&modify_field;
post '/rating_table/new_field'    => \&modify_field;

post '/rating_table/new_prefix'   => \&new_prefix;

'CCNQ::Portal::Inner::RatingTable';

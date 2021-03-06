package CCNQ::Portal::Inner::Number;
# Copyright (C) 2010  Stephane Alnet
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

=head1 number_type

A number_type is used by a customer to select a number (for example
during self-ordering). For example "Metered DID", "Unlimited DID",
"Toll-Free", etc.

=cut

our $number_types;

sub register_number_types {
  my $self = shift;
  my ($new_types) = @_;
  $number_types ||= {};
  $number_types = {
    %$number_types,
    %$new_types,
  };
  return;
}

sub registered_number_types {
  my $self = shift;
  return $number_types;
}

=head1 carrier

A carrier is used by management personel to identify a carrier,
carrier trunk, carrier trunk type, etc.

=cut

our $carriers;

sub register_carriers {
  my $self = shift;
  my ($new_carriers) = @_;
  $carriers ||= {};
  $carriers = {
    %$carriers,
    %$new_carriers,
  };
  return;
}

sub registered_carriers {
  my $self = shift;
  return $carriers;
}

use CCNQ::AE;
use CCNQ::API;

# Number routing form.
# This updates:
#  - the endpoint
#  - the "profile" on the client-sbc

sub default {
  my ($category_to_criteria) = @_;

  CCNQ::Portal->current_session->user
    or return CCNQ::Portal::content( error => _('Unauthorized')_ );

  my $account = CCNQ::Portal::Inner::Util::validate_account;
  $account
    or return CCNQ::Portal::content( error => _('Please select an account')_ );

  my $category = params->{category};
  my $cluster  = params->{cluster};

  my $endpoints = CCNQ::Portal::Inner::Util::endpoints_for($account);

  if( $category and
      $category_to_criteria and
      $category_to_criteria->{$category} )
  {
    my $selector = $category_to_criteria->{$category};
    $endpoints = [ grep { $selector->($_) } @$endpoints ];
  }

  CCNQ::Portal->current_session->user->profile->is_admin
    and var available_numbers => sub {
      my $cv = AE::cv;
      CCNQ::API::provisioning('report','number_bank',$cv);
      return CCNQ::AE::receive_docs($cv);
    };

  var category => $category;
  var cluster  => $cluster;
  var numbers_for   => \&CCNQ::Portal::Inner::Util::numbers_for;
  var endpoints_for => \&CCNQ::Portal::Inner::Util::endpoints_for;
  var locations_for => \&CCNQ::Portal::Inner::Util::locations_for;

  return CCNQ::Portal::content;
}

sub get_default {
  var template_name => 'api/number';
  default(@_);
}

sub submit_number {
  my ($api_name) = @_;
  my $normalize_number = \&CCNQ::Portal::normalize_number;

  CCNQ::Portal->current_session->user
    or return CCNQ::Portal::content( error => _('Unauthorized')_ );

  my $account = CCNQ::Portal::Inner::Util::validate_account;
  $account
    or return CCNQ::Portal::content( error => _('Please select an account')_ );

  my $endpoint = params->{endpoint};
  return CCNQ::Portal::content unless $endpoint;

  my $endpoint_data = CCNQ::Portal::Inner::Util::get_endpoint($account,$endpoint);

  my $number = $normalize_number->(params->{number_alt} || params->{number});
  $number
    or return CCNQ::Portal::content( error => _('Please specify a valid number')_ );

  my $params = CCNQ::Portal::Inner::Util::get_number($account,$number);

  # Validate that the number is in this account.
  CCNQ::Portal->current_session->user->profile->is_admin ||
  $params->{account} eq $account
    or return CCNQ::Portal::content( error => _('Unauthorized for this number')_ );

  $params = {
    %$params,
    api_name      => $api_name,
    account       => $endpoint_data->{account},
    account_sub   => $endpoint_data->{account_sub},
    endpoint      => $endpoint_data->{endpoint},
    endpoint_ip   => $endpoint_data->{ip},
    register      => $endpoint_data->{password} ? 1 : 0,
    username      => $endpoint_data->{username},
    username_domain => $endpoint_data->{domain},
    cluster       => $endpoint_data->{cluster},
    category      => $endpoint_data->{category},
    number        => $number,
    location      => params->{location},
  };

  CCNQ::Portal::Util::neat($params,qw(
    inbound_username
  ));

  $params->{location} ||= $endpoint_data->{location}
    if CCNQ::Portal->site->numbers_require_location ||
       CCNQ::Portal->site->update_location_for_number;

  return CCNQ::Portal::Inner::Util::update_number($account,$number,$params);
}

sub submit_default {
  my ($category_to_route) = @_;

  var template_name => 'api/number';

  exists(vars->{cluster_to_profiles}->{params->{cluster}}) &&
  exists(vars->{cluster_to_profiles}->{params->{cluster}}->{params->{inbound_username}}) &&
  exists(vars->{category_to_criteria}->{params->{category}})
  # and category_to_criteria->{params->{category}}->($endpoint)
    or return CCNQ::Portal::content( error => _('Invalid parameters')_ );

  return submit_number($category_to_route->{params->{category}});
}

1;

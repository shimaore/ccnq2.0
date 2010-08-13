package CCNQ::Portal::Inner::Util;
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
use strict; use warnings; use Carp;
use utf8;

use CCNQ::Portal;
use CCNQ::Portal::I18N;
use CCNQ::Portal::Util;

use AnyEvent;
use AnyEvent::DNS;

use CCNQ::AE;
use CCNQ::API;

=head1 Account Utilities

=head2 account_subs($account)

=cut

sub account_subs {
  my ($account) = @_;

  defined($account) or confess "account is required";

  my $cv = AE::cv;
  CCNQ::API::billing('report','account_subs',$account,$cv);
  return CCNQ::AE::receive_docs($cv);
}

=head2 account_sub_data($account,$account_sub)

=cut

sub account_sub_data {
  my ($account,$account_sub) = @_;

  defined($account) or confess "account is required";
  defined($account_sub) or confess "account_sub is required";

  my $cv = AE::cv;
  CCNQ::API::billing('report','account_subs',$account,$account_sub,$cv);
  return CCNQ::AE::receive_first_doc($cv);
}

=head2 portal_users($account)

=cut

sub portal_users {
  my ($account) = @_;

  defined($account) or confess "account must be defined";

  my $cv1 = CCNQ::Portal::db->view('report/portal_users_by_account', {
    startkey => [$account],
    endkey   => [$account,{}],
  });
  return CCNQ::AE::receive_ids($cv1);
}

=head2 user_can_access_billing_for($account)

=cut

sub user_can_access_billing_for {
  my ($account) = @_;

  CCNQ::Portal->current_session->user->is_admin
    and return 1;

  my $user_id = CCNQ::Portal->current_session->user->id;

  my $cv = AE::cv;
  CCNQ::API::billing('report','users',$user_id,$cv);
  my $billing_user_data = CCNQ::AE::receive_first_doc($cv);

  return scalar grep { $_ eq $account } @{$billing_user_data->billing_accounts};
}

=head1 Plan Utilities

=head2 get_plans()

=cut

sub get_plans {
  my $cv = AE::cv;
  CCNQ::API::billing('report','plans','',$cv);
  return CCNQ::AE::receive_docs($cv);
}

=head1 Bucket Utilities

=head2 get_buckets($name)

Retrieve billing (meta)data about a bucket.

=head2  get_buckets()

Retrieve billing (meta)data about all buckets.

=cut

sub get_buckets {
  my ($name) = @_;

  # name is optional

  my $cv = AE::cv;
  if(defined($name)) {
    CCNQ::API::billing('report','buckets',$name,$cv);
  } else {
    CCNQ::API::billing('report','buckets',$cv);
  }
  my $buckets = CCNQ::AE::receive_docs($cv);
  return $buckets;
}

=head2 get_account_bucket($name,$account[,$account_sub])

Return the current instance value.

=cut

sub get_account_bucket {
  my ($name,$account,$account_sub) = @_;

  defined($name)    or confess "name is required";
  defined($account) or confess "account is required";
  # account_sub is optional (in case the bucket does "use_account").

  my $cv = AE::cv;
  if(defined $account_sub) {
    CCNQ::API::bucket_query({ name => $name, account => $account, account_sub => $account_sub },$cv);
  } else {
    CCNQ::API::bucket_query({ name => $name, account => $account },$cv);
  }
  my $data = CCNQ::AE::receive($cv);
  return $data;
}

=head1 Endpoint Utilities

=cut

use constant STATIC_ENDPOINTS_CLUSTERS_DNS_NAME  => 'static.clusters';
use constant DYNAMIC_ENDPOINTS_CLUSTERS_DNS_NAME => 'dynamic.clusters';

use constant::defer clusters_for_static_endpoints => sub {
  my $dns_txt = sub {
    my $dn = CCNQ::Install::catdns(@_);
    my $cv = AE::cv;
    AnyEvent::DNS::txt( $dn, $cv );
    return ($cv->recv);
  };

  return [sort $dns_txt->(CCNQ::Install::cluster_fqdn(STATIC_ENDPOINTS_CLUSTERS_DNS_NAME))];
};

use constant::defer clusters_for_dynamic_endpoints => sub {
  my $dns_txt = sub {
    my $dn = CCNQ::Install::catdns(@_);
    my $cv = AE::cv;
    AnyEvent::DNS::txt( $dn, $cv );
    return ($cv->recv);
  };

  return [sort $dns_txt->(CCNQ::Install::cluster_fqdn(DYNAMIC_ENDPOINTS_CLUSTERS_DNS_NAME))];
};

sub endpoints_for {
  my ($account) = @_;
  defined($account) or confess "account is required";

  my $cv = AE::cv;
  CCNQ::API::provisioning('report','endpoint',$account,$cv);
  return CCNQ::AE::receive_docs($cv);
}

sub get_endpoint {
  my ($account,$endpoint) = @_;


  my $cv = AE::cv;
  CCNQ::API::provisioning('report','endpoint',$account,$endpoint,$cv);
  return CCNQ::AE::receive_first_doc($cv) || {};
}

sub update_endpoint {
  my ($account,$endpoint,$new_data) = @_;
  defined($account) or confess "account is required";
  defined($endpoint) or confess "endpoint is required";
  defined($new_data) or confess "new_data is required";

  my $endpoint_data = get_endpoint($account,$endpoint);

  my $params = {
    %$endpoint_data, # Keep any existing information (this means data must be overwritten)
    %$new_data,
  };

  # Update the information in the API.
  my $cv = AE::cv;
  CCNQ::API::api_update('endpoint',$params,$cv);
  return CCNQ::Portal::Util::redirect_request($cv);
}

=head1 Number Utilities

=cut

sub get_number {
  my ($account,$number) = @_;
  defined($account) or confess "account is required";
  defined($number) or confess "number is required";

  my $cv = AE::cv;
  CCNQ::API::provisioning('report','number',$account,$number,$cv);
  return CCNQ::AE::receive_first_doc($cv) || {};
}

sub numbers_for {
  my ($account) = @_;
  defined($account) or confess "account is required";

  my $cv = AE::cv;
  CCNQ::API::provisioning('report','number',$account,$cv);
  return CCNQ::AE::receive_docs($cv);
}

sub update_number {
  my ($account,$number,$new_data) = @_;
  defined($account) or confess "account is required";
  defined($number) or confess "number is required";
  defined($new_data) or confess "new_data is required";

  my $number_data = get_number($account,$number);

  my $params = {
    %$number_data, # Keep any existing information (this means data must be overwritten)
    %$new_data,
  };

  my $api_name = $params->{api_name};
  return CCNQ::Portal::content unless $api_name;

  # Update the information in the API.
  my $cv = AE::cv;
  CCNQ::API::api_update($api_name,$params,$cv);
  return CCNQ::Portal::Util::redirect_request($cv);
}

=head1 Location Utilities

=cut

sub get_location {
  my ($account,$location) = @_;
  defined($account) or confess "account is required";
  defined($location) or confess "location is required";

  my $cv = AE::cv;
  CCNQ::API::provisioning('report','location',$account,$location,$cv);
  return CCNQ::AE::receive_first_doc($cv) || {};
}

sub locations_for {
  my ($account) = @_;
  defined($account) or confess "account is required";

  my $cv = AE::cv;
  CCNQ::API::provisioning('report','location',$account,$cv);
  return CCNQ::AE::receive_docs($cv);
}

sub update_location {
  my ($account,$location,$new_data) = @_;
  defined($account) or confess "account is required";
  defined($location) or confess "location is required";
  defined($new_data) or confess "new_data is required";

  my $location_data = get_location($account,$location);

  my $params = {
    %$location_data, # Keep any existing information (this means data must be overwritten)
    %$new_data,
  };

  # Update the information in the API.
  my $cv = AE::cv;
  CCNQ::API::api_update('location',$params,$cv);
  return CCNQ::Portal::Util::redirect_request($cv);
}

=head1 Plan Utilities

=cut

sub get_currencies {
  return { 'EUR' => '€', 'USD' => 'US$' };
}

=head1 CDR Utilities

=cut

our %event_types = (
  'egress_call'  => 1,
  'ingress_call' => 2,
  'endpoint_update' => 1000,
  'endpoint_delete' => 1001,
);

sub register_event_type {
  my ($type,$order) = @_;
  defined($type) or confess "type is required";
  defined($order) && int($order) or confess "order is required";

  $event_types{$type} = int($order);
}

sub event_types {
  return sort { $event_types{$a} <=> $event_types{$b} } keys %event_types;
}

'CCNQ::Portal::Inner::Util';

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
use strict; use warnings;
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

  defined($account) or die "account is required";

  my $cv = AE::cv;
  CCNQ::API::billing('report','account_subs',$account,$cv);
  return CCNQ::AE::receive_docs($cv);
}

=head2 account_sub_data($account,$account_sub)

=cut

sub account_sub_data {
  my ($account,$account_sub) = @_;

  defined($account) or die "account is required";
  defined($account_sub) or die "account_sub is required";

  my $cv = AE::cv;
  CCNQ::API::billing('report','account_subs',$account,$account_sub,$cv);
  return CCNQ::AE::receive_first_doc($cv);
}

=head2 portal_users($account)

=cut

sub portal_users {
  my $account = shift;

  defined($account) or die "account must be defined";

  my $cv1 = CCNQ::Portal::db->view('report/portal_users_by_account', {
    startkey => [$account],
    endkey   => [$account,{}],
  });
  return CCNQ::AE::receive_ids($cv1);
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
  my $buckets = CCNQ::AE::receive($cv);
  return $buckets;
}

=head2 get_account_bucket($name,$account[,$account_sub])

Return the current instance value.

=cut

sub get_account_bucket {
  my ($name,$account,$account_sub) = @_;

  defined($name)    or die "name is required";
  defined($account) or die "account is required";
  # account_sub is optional (in case the bucket does "use_account").

  my $cv = AE::cv;
  CCNQ::API::bucket_query({ name => $name, account => $account, account_sub => $account_sub },$cv);
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
  my $account = shift;
  my $cv3 = AE::cv;
  CCNQ::API::provisioning('report','endpoint',$account,$cv3);
  my $endpoints = CCNQ::AE::receive($cv3);
  my @endpoints = map { $_->{doc} } @{$endpoints->{rows} || []};
  return [@endpoints];
}

sub get_endpoint {
  my ($account,$endpoint) = @_;
  my $cv = AE::cv;
  CCNQ::API::provisioning('report','endpoint',$account,$endpoint,$cv);
  return CCNQ::AE::receive_first_doc($cv) || {};
}

=head1 Plan Utilities

=cut

sub get_currencies {
  return { 'EUR' => '€', 'USD' => 'US$' };
}



'CCNQ::Portal::Inner::Util';

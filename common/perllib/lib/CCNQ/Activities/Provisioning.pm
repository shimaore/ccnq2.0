package CCNQ::Activities::Provisioning;
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

use Carp;
use CCNQ::Provisioning;

sub __update {
  my $request = shift;

  # Not required for number bank.
  # croak "No account" unless
  #  defined $request->{account};
  # Not required for location.
  # croak "No account_sub" unless
  #  defined $request->{account_sub};
  croak "No request type" unless
    defined $request->{type}; # normally auto-populated by node/api

  # Return list of activities required to complete this request.
  return (
    {
      action => 'provisioning_update',
      cluster_name => CCNQ::Provisioning::PROVISIONING_CLUSTER_NAME,
      params => $request, # at least _id is required
    },
  );
}

sub __delete {
  my $request = shift;
  # Return list of activities required to complete this request.
  return (
    {
      action => 'provisioning_delete',
      cluster_name => CCNQ::Provisioning::PROVISIONING_CLUSTER_NAME,
      params => {
        _id => $request->{_id}, # at least _id is required
      }
    },
  );
}

=head1 Provisioning content-specific tools

These functions are used to unify the naming conventions inside the
provisioning database.

The following "record" profiles are defined:
- number   -- a manager request for a specific number
- endpoint -- a manager request for a specific endpoint
- location -- a manager request for a specific location (esp. emergency location)

=cut

sub _update {
  my ($request,$profile) = @_;
  croak "No $profile" unless
    defined $request->{$profile};
  return __update({
    %$request,
    _id => join('/',$profile,$request->{$profile}),
    profile => $profile,
  });
}

sub _delete {
  my ($request,$profile) = @_;
  croak "No $profile" unless
    defined $request->{$profile};
  return __delete({
    _id => join('/',$profile,$request->{$profile}),
  });
}

sub update_number   { return _update(@_,'number'  ); }
sub update_endpoint { return _update(@_,'endpoint'); }
sub update_location { return _update(@_,'location'); }

sub delete_number   { return _delete(@_,'number'  ); }
sub delete_endpoint { return _delete(@_,'endpoint'); }
sub delete_location { return _delete(@_,'location'); }

'CCNQ::Activities::Provisioning';

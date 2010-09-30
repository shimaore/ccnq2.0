package CCNQ::Activities::Proxy;

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

use Carp;

sub domain_update {
  my $self = shift;
  my $request = shift;

  $request->{cluster_name} or croak "No cluster_name";

  # Return list of activities required to complete this request.
  return (
    {
      action => 'domain/update',
      cluster_name => $request->{cluster_name},
      params => { map { $_ => $request->{$_} } qw(
          domain
      )}
    },
  );
}

sub domain_delete {
  my $self = shift;
  my $request = shift;

  $request->{cluster_name} or croak "No cluster_name";

  # Return list of activities required to complete this request.
  return (
    {
      action => 'domain/delete',
      cluster_name => $request->{cluster_name},
      params => { map { $_ => $request->{$_} } qw(
        domain
      )}
    },
  );
}

sub dr_gateway_update {
  my $self = shift;
  my $request = shift;

  $request->{cluster_name} or croak "No cluster_name";

  # Return list of activities required to complete this request.
  return (
    {
      action => 'dr_gateway/update',
      cluster_name => $request->{cluster_name},
      params => { map { $_ => $request->{$_} } qw(
          id
          target
          strip_digit
          prefix
          realm
          login
          password
          force_mp
          description
      )}
    },
    {
      action => 'dr_reload',
      cluster_name => $request->{cluster_name},
    }
  );
}

sub dr_gateway_delete {
  my $self = shift;
  my $request = shift;

  $request->{cluster_name} or croak "No cluster_name";

  # Return list of activities required to complete this request.
  return (
    {
      action => 'dr_gateway/delete',
      cluster_name => $request->{cluster_name},
      params => { map { $_ => $request->{$_} } qw(
          id
      )}
    },
    {
      action => 'dr_reload',
      cluster_name => $request->{cluster_name},
    }
  );
}

sub dr_rule_update {
  my $self = shift;
  my $request = shift;

  $request->{cluster_name} or croak "No cluster_name";

  # Return list of activities required to complete this request.
  return (
    {
      action => 'dr_rule/update',
      cluster_name => $request->{cluster_name},
      params => { map { $_ => $request->{$_} } qw(
          outbound_route
          description
          prefix
          priority
          target
      )}
    },
    {
      action => 'dr_reload',
      cluster_name => $request->{cluster_name},
    }
  );
}

sub dr_rule_delete {
  my $self = shift;
  my $request = shift;

  $request->{cluster_name} or croak "No cluster_name";

  # Return list of activities required to complete this request.
  return (
    {
      action => 'dr_rule/delete',
      cluster_name => $request->{cluster_name},
      params => { map { $_ => $request->{$_} } qw(
        outbound_route
        prefix
        priority
      )}
    },
    {
      action => 'dr_reload',
      cluster_name => $request->{cluster_name},
    }
  );
}

sub inbound_update {
  my $self = shift;
  my $request = shift;

  $request->{cluster_name} or croak "No cluster_name";

  # Return list of activities required to complete this request.
  return (
    {
      action => 'inbound/update',
      cluster_name => $request->{cluster_name},
      params => { map { $_ => $request->{$_} } qw(
          source
      )}
    },
    {
      action => 'trusted_reload',
      cluster_name => $request->{cluster_name},
    }
  );
}


sub inbound_delete {
  my $self = shift;
  my $request = shift;

  $request->{cluster_name} or croak "No cluster_name";

  # Return list of activities required to complete this request.
  return (
    {
      action => 'inbound/delete',
      cluster_name => $request->{cluster_name},
      params => { map { $_ => $request->{$_} } qw(
        source
      )}
    },
    {
      action => 'trusted_reload',
      cluster_name => $request->{cluster_name},
    }
  );
}

sub local_number_update {
  my $self = shift;
  my $request = shift;

  $request->{cluster_name} or croak "No cluster_name";

  # Return list of activities required to complete this request.
  return (
    {
      action => 'local_number/update',
      cluster_name => $request->{cluster_name},
      params => { map { $_ => $request->{$_} } qw(
          number
          domain
          username
          username_domain
          cfa
          cfnr
          cfb
          cfda
          cfda_timeout
          outbound_route
          account
          account_sub
          location
      )}
    },
  );
}


sub local_number_delete {
  my $self = shift;
  my $request = shift;

  $request->{cluster_name} or croak "No cluster_name";

  # Return list of activities required to complete this request.
  return (
    {
      action => 'local_number/delete',
      cluster_name => $request->{cluster_name},
      params => { map { $_ => $request->{$_} } qw(
        number
        domain
      )}
    },
  );
}

sub endpoint_update {
  my $self = shift;
  my $request = shift;

  $request->{cluster_name} or croak "No cluster_name";

  # Return list of activities required to complete this request.
  return (
    {
      action => 'endpoint/update',
      cluster_name => $request->{cluster_name},
      params => { map { $_ => $request->{$_} } qw(
          username
          domain
          password
          ip
          port
          srv
          via
          dest_domain
          strip_digit
          account
          account_sub
          allow_onnet
          src_disabled
          dst_disabled
          always_proxy_media
          forwarding_sbc
          outbound_route
          ignore_caller_outbound_route
          ignore_default_outbound_route
          check_from
          location
      )}
    },
  );
}


sub endpoint_delete {
  my $self = shift;
  my $request = shift;

  $request->{cluster_name} or croak "No cluster_name";

  # Return list of activities required to complete this request.
  return (
    {
      action => 'endpoint/delete',
      cluster_name => $request->{cluster_name},
      params => { map { $_ => $request->{$_} } qw(
        username
        domain
        ip
      )}
    },
  );
}

sub endpoint_number_update {
  my $self = shift;
  my $request = shift;

  $request->{cluster_name} or croak "No cluster_name";

  # Return list of activities required to complete this request.
  return (
    {
      action => 'endpoint_number/update',
      cluster_name => $request->{cluster_name},
      params => { map { $_ => $request->{$_} } qw(
          username
          domain
          number
      )}
    },
  );
}

sub endpoint_number_delete {
  my $self = shift;
  my $request = shift;

  $request->{cluster_name} or croak "No cluster_name";

  # Return list of activities required to complete this request.
  return (
    {
      action => 'endpoint_number/delete',
      cluster_name => $request->{cluster_name},
      params => { map { $_ => $request->{$_} } qw(
          username
          domain
          number
      )}
    },
  );
}

sub location_update {
  my $self = shift;
  my $request = shift;

  $request->{cluster_name} or croak "No cluster_name";

  # Return list of activities required to complete this request.
  return (
    {
      action => 'location/update',
      cluster_name => $request->{cluster_name},
      params => { map { $_ => $request->{$_} } qw(
          location
          domain
          routing_data
      )}
    },
  );
}


sub location_delete {
  my $self = shift;
  my $request = shift;

  $request->{cluster_name} or croak "No cluster_name";

  # Return list of activities required to complete this request.
  return (
    {
      action => 'location/delete',
      cluster_name => $request->{cluster_name},
      params => { map { $_ => $request->{$_} } qw(
          location
          domain
      )}
    },
  );
}


'CCNQ::Activities::Proxy';

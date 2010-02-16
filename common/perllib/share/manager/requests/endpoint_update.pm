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

sub {
  my $request = shift;
  # Return list of activities required to complete this request.
  return (
    {
      action => 'subscriber/update',
      cluster_name => $request->{cluster_name},
      params => {
        map { $_ => $request->{$_} } qw(
          username
          domain
          password
          ip
          port
          srv
          dest_domain
          strip_digit
          account
          account_sub
          allow_onnet
          always_proxy_media
          forwarding_sbc
          outbound_route
          ignore_caller_outbound_route
          ignore_default_outbound_route
          check_from
        )
      }
    },
  );
}

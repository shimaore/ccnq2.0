package CCNQ::Proxy::endpoint_location;
# Copyright (C) 2006, 2007  Stephane Alnet
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
#

use strict; use warnings;

use base qw(CCNQ::SQL::Base);
use AnyEvent;
use Logger::Syslog;

use constant LOCATION_COLUMNS => [qw(
  username
  domain
  contact
  received
  path
  expires
  q
  callid
  cseq
  last_modified
  flags
  cflags
  user_agent
  socket
  methods
)];

use constant LOCATION_SQL_QUERY =>
  'SELECT _columns_ FROM location WHERE username = ? AND domain = ?';

sub do_query {
  my ($self,$params) = @_;

  my $username = $params->{username};
  my $domain   = $params->{domain};

  # Force an error for invalid parameters.
  return $self->do_sql_query()
    unless defined($username) && $username ne ''
        && defined($domain)   && $domain   ne '';

  return $self->do_sql_query(LOCATION_SQL_QUERY,LOCATION_COLUMNS,[$username,$domain]);
}

'CCNQ::Proxy::endpoint_location';

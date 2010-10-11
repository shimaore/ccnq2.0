package CCNQ::Proxy::dr_rule;
# Copyright (C) 2006, 2007  Stephane Alnet
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
#

use strict; use warnings;

use base qw(CCNQ::Proxy::Base);
use Logger::Syslog;

sub insert
{
    my ($self,$params) = @_;
    my $groupid     = $params->{outbound_route};
    my $prefix      = $params->{prefix} || '';
    my $priority    = $params->{priority};
    my $gwlist      = $params->{target};

    return ()
      unless defined $groupid  && $groupid =~ /^\d+$/
      and    defined $priority && $priority ne ''
      and    defined $gwlist   && $gwlist   ne '';

    my $description = $groupid == 0 ? 'Default' : $params->{description};
    $description ||= '(none given)';

    my @res;
    push @res,
        <<"SQL",[$groupid,$prefix,'',$priority,'',$gwlist,$description];
        INSERT INTO dr_rules(groupid,prefix,timerec,priority,routeid,gwlist,description) VALUES (?,?,?,?,?,?,?)
SQL
    return @res;
}

sub delete
{
    my ($self,$params) = @_;
    my $groupid     = $params->{outbound_route};
    my $prefix      = $params->{prefix};
    my $priority    = $params->{priority};

    return ()
      unless defined $groupid  && $groupid  ne ''
      and    defined $priority && $priority ne '';

    my @res;
    push @res,
        <<'SQL',[$groupid,$prefix,$priority];
        DELETE FROM dr_rules WHERE groupid = ? AND prefix = ? AND priority = ?
SQL
    return @res;
}

1;

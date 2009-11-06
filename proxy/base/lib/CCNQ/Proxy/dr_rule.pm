package CCNQ::Proxy::dr_rule;
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

#
# For more information visit http://carrierclass.net/
#
use strict; use warnings;

use base qw(CCNQ::Proxy::Base);
use Logger::Syslog;

=pod

sub form
{
    my $self = shift;
    return (
        'Group'       => 'text', # 0 for default, otherwise user-specific (via dr_groups)
        'Description' => 'text',
        'Prefix'      => 'text',
        'Priority'    => 'text',
        'Target'      => $self->list_of_gateways(), # For now we can select only one gateway
    );
}

=cut

=pod
sub id_of_gateway {
  my ($self,$target) = @_;
  my $id = $self->run_sql_once('SELECT gwid FROM dr_gateways WHERE target = ?',$target);
  warning("Unknown gateway/target $target") if !defined $id;
  return defined($id) ? $id : $target;
}
=cut

sub insert
{
    my ($self,$params) = @_;
    my $groupid     = $params->{group};
    my $description = $groupid == 0 ? 'Default' : $params->{description};
    my $prefix      = $params->{prefix};
    my $priority    = $params->{priority};
    my $gwlist      = $params->{target};
=pod
    my $gwlist = join(';', map {
                    join(',', map {
                      id_of_gateway($_)
                    } split(/,/))
                  } split(/;/,$gwlist));
=cut

    my @res;
    push @res,
        <<'SQL',[$groupid,$prefix,'',$priority,'',$gwlist,$description];
        INSERT INTO dr_rules(groupid,prefix,timerec,priority,routeid,gwlist,description) VALUES (?,?,?,?,?,(SELECT gwid FROM dr_gateways WHERE address = ?),?)
SQL
    return @res;
}

sub delete
{
    my ($self,$params) = @_;
    my $groupid     = $params->{group};
    my $prefix      = $params->{prefix};
    my $priority    = $params->{priority};

    my @res;
    push @res,
        <<'SQL',[$groupid,$prefix,$priority];
        DELETE FROM dr_rules WHERE groupid = ? AND prefix = ? AND priority = ?
SQL
    return @res;
}

sub list
{
    my $self = shift;

    return (<<'SQL',[],undef);
            SELECT DISTINCT groupid AS "Group", description AS "Description", prefix AS "Prefix", priority AS "Priority", gwlist AS "Target"
            FROM dr_rules main
            ORDER BY groupid, prefix, priority ASC
SQL
}

1;
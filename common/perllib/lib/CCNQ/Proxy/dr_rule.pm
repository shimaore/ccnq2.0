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

use strict; use warnings;

use base qw(CCNQ::Proxy::Base);
use Logger::Syslog;

=pod

sub form
{
    my $self = shift;
    return (
        'Outbound_Route' => 'text', # 0 for default, otherwise user-specific (via dr_groups)
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

sub sql_concat {
  my $separator = shift;
  if($#_ > 0) {
    # XXX CONCAT_WS is a MySQL-ism
    return qq{CONCAT_WS('$separator',}.join(',',@_).q{)};
  }
  if($#_ == 0) {
    return $_[0];
  }
  return ''; # Should not happen, unless $gwlist is improperly formatted
}

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

    my @sql_params = split(/[,;]/,$gwlist);

    my $sql_fragment =
      sql_concat(';',map{ sql_concat(',',map{
          '(SELECT gwid FROM dr_gateways WHERE address = ?)'
        } split(/,/))
      } split(/;/,$gwlist));

    my @res;
    push @res,
        <<"SQL",[$groupid,$prefix,'',$priority,'',@sql_params,$description];
        INSERT INTO dr_rules(groupid,prefix,timerec,priority,routeid,gwlist,description) VALUES (?,?,?,?,?,${sql_fragment},?)
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

sub list
{
    my $self = shift;

    return (<<'SQL',[],undef);
            SELECT DISTINCT groupid AS "Outbound_Route", description AS "Description", prefix AS "Prefix", priority AS "Priority", gwlist AS "Target"
            FROM dr_rules main
            ORDER BY groupid, prefix, priority ASC
SQL
}

1;
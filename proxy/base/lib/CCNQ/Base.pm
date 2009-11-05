package CCNQ::Base;
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

use base qw(CCNQ::SQL);

use Logger::Syslog;

sub _build_callback {
  my ($db,$sql,$args,$cb) = @_;
  debug("Postponing $sql with (".join(',',@{$args}).") and callback $cb");
  return sub {
    debug("Executing $sql with (".join(',',@{$args}).") and callback $cb");
    $db->exec($sql,@{$args},$cb);
  };
}

sub do_sql {
  my ($self,@cmds) = @_;

  my $db = $self->_db;

  my $cv = AnyEvent->condvar;

  my $run = sub {
    $db->commit( sub {
      $cv->send(['ok']);
    });
  };

  while(@cmds) {
    my $args = pop(@cmds) || [];
    my $sql  = pop(@cmds);
    $run = _build_callback($db,$sql,$args,$run);
  }

  $db->begin_work( $run );

  return $cv;
}

sub do_insert
{
    my ($self,$params) = @_;
    return $self->do_sql($self->insert($params));
}

sub do_delete
{
    my ($self,$params) = @_;
    return $self->do_sql($self->delete($params));
}

sub do_modify
{
    my ($self,$params) = @_;

    # Split the parameters into two lists: one with the old values
    # (used to delete the existing record) and one with the new values
    # (used to create a new record).
    my $old_params = {};
    my $new_params = {};
    while( my ($name,$value) = each %{$params} )
    {
        if($name =~ /:old$/)
        {
            $name =~ s/:old$//;
            $old_params->{$name} = $value;
        }
        else
        {
            $new_params->{$name} = $value;
        }
    }

    return $self->do_sql($self->delete($old_params),$self->insert($new_params));
}

sub do_update
{
    my ($self,$params) = @_;

    # Split the parameters into two lists: one with the old values
    # (used to delete the existing record) and one with the new values
    # (used to create a new record).
    my $old_params = {%{$params}};
    my $new_params = {%{$params}};

    return $self->do_sql($self->delete($old_params),$self->insert($new_params));
}

=pod
sub do_list
{
    my $self = shift;
    my ($sql_callback,$output_callback,$list_params) = @_;

    my ($sql,$params,$post_process) = $self->list($list_params);

    $sql = $sql_callback->($sql);

    ## XXX Replace with callback
    my $sth = $self->run_sql_command($sql,$params);
    return if not $sth;
    my $names = $sth->{NAME};
    my $nb_rows = 0;
    while(my $content = $sth->fetchrow_arrayref)
    {
        my ($_content,$_names) = ($content,$names);
        ($_content,$_names) = $post_process->($_content,$_names) if defined $post_process;
        $output_callback->($_content,$_names);
        $nb_rows++;
    }
    return $nb_rows;
}

sub do_query
{
    my ($self,$params) = @_;

    my $result = {};
    my @rows = ();

    my $sql_callback = sub
    {
        my $sql = shift;

        $sql .= " LIMIT $params->{_limit}",
        $result->{limit} = $params->{_limit}
            if exists $params->{_limit}
            and defined $params->{_limit};

        $sql .= " OFFSET $params->{_offset}",
        $result->{offset} = $params->{_offset}
            if exists $params->{_offset}
            and defined $params->{_offset};
        return $sql;
    };

    my $result_callback = sub
    {
        my ($content,$names) = @_;
        # No content?
        return unless defined $content and $content;

        my %values;

        my @content = @{$content};
        for my $name (@{$names})
        {
          my $value = shift @content;
          my $display_name = $name;
          $display_name =~ s/[!*]$//;

          $values{lc($display_name)} = $value
            unless $name =~ /!$/; # no value
        }

        push @rows, {%values};
    };

    my $nb_rows = $self->do_list($sql_callback,$result_callback,$params);
    $result->{total_rows} = $nb_rows;
    $result->{rows} = [@rows];

    return ['ok',$result];
}
=cut

sub run
{
    my $self = shift;
    my ($action,$params) = @_;

    # This would need an eval() to collect error messages,
    # unless I rewrite the code to work properly.
    return $self->do_delete($params) if $action eq 'delete';
    return $self->do_insert($params) if $action eq 'insert';
    return $self->do_modify($params) if $action eq 'modify';
    return $self->do_update($params) if $action eq 'update';
=pod
    return $self->do_query($params)  if $action eq 'query';
=cut

    error("Invalid action $action");
    return undef;
}

1;

package CCNQ::SQL::Base;
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

use base qw(CCNQ::SQL);

use Logger::Syslog;
use AnyEvent;
use CCNQ::Install;

sub do_sql {
  my ($self,@cmds) = @_;

  my $db = $self->_db;

  my $cv = AE::cv;

  my $error = sub {
    error(join(',',@_));
    $cv->send([@_]);
  };

  my $build_callback = sub {
    my ($sql,$args,$cb) = @_;
    debug("Postponing $sql with (".join(',',@{$args}).") and callback $cb");
    return sub {
      $error->('Database error: [_1]',$@) if $@;
      debug("Executing $sql with (".join(',',@{$args}).") and callback $cb");
      $db->exec($sql,@{$args},$cb);
    };
  };

  my $run = sub {
    $error->('Database error: [_1]',$@) if $@;
    $db->commit(sub {
      $error->('Database error: [_1]',$@) if $@;
      # It seems the documentation for AnyEvent::DBI is incorrect.
      # $error->('Commit failed') unless $_[1];
      $cv->send;
    });
  };

  while(@cmds) {
    my $args = pop(@cmds) || [];
    my $sql  = pop(@cmds);
    $run = $build_callback->($sql,$args,$run);
  }

  $db->begin_work( $run );

  return $cv;
}

sub do_sql_query {
  my ($self,$sql,$columns,$args) = @_;

  my $db = $self->_db;

  my $cv = AE::cv;

  my $error = sub {
    error(join(',',@_));
    $cv->send([@_]);
  };

  $error->('Invalid query') unless $sql && $columns;

  $sql =~ s/_columns_/join(',',map { qq("$_") } @{$columns} )/ge;

  my $cb = sub{
    $error->('Database error: [_1]',$@) if $@;

    my ($dbh, $rows, $rv) = @_;
    $#_ or $error->('Database error: [_1]',$@);
    my %a;
    $cv->send({
      rows => [
        map {
          @a{@$columns} = @$_, {%a} # hash-slice the values, return the hash
        } @$rows
      ],
    });
  };

  debug("Postponing $sql with (".join(',',@{$args}).") and callback $cb");

  $db->exec($sql,@{$args},$cb);

  return $cv;
}

sub do_delete
{
    my ($self,$params) = @_;

    my @delete_commands = $self->delete($params);

    if(!@delete_commands) {
      die ["Invalid parameters"];
    }

    return $self->do_sql(@delete_commands);
}

sub do_update
{
    my ($self,$params) = @_;

    # Split the parameters into two lists: one with the old values
    # (used to delete the existing record) and one with the new values
    # (used to create a new record).
    my $old_params = {%{$params}};
    my $new_params = {%{$params}};

    my @delete_commands = $self->delete($old_params);
    my @insert_commands = $self->insert($new_params);

    # Parameter errors are indicated by the methods returning
    # empty lists.
    if(!@delete_commands || !@insert_commands) {
      die ["Invalid parameters"];
    }

    return $self->do_sql(@delete_commands,@insert_commands);
}

sub run
{
    my $self = shift;
    my ($action,$params) = @_;

    # This would need an eval() to collect error messages,
    # unless I rewrite the code to work properly.
    return $self->do_delete($params) if $action eq 'delete';
    return $self->do_update($params) if $action eq 'update';
    return $self->do_query($params) if $action eq 'query';

    die ['Invalid action [_1]',$action];
}

1;

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

use base qw(CCNQ::Object);

sub _init
{
    my $self = shift;
    my ($db) = @_;
    $self->{_db}       = $db;
}

sub class { my $c = ref(shift); $c =~ s/^.*:://; return $c; }

sub _db  { shift->{_db} }

sub method
{
    my $self = shift;
    my $method = $self->_cgi->param('_method');
    $method = 'list' if not defined $method;
    return $method;
}

=pod
    sub new_precondition(@params)
        Returns true if the parameters are valid for insertion, false otherwise.

=cut

sub new_precondition
{
    my $self = shift;
    my %params = @_;

    return 1;
}

sub do_insert()
{
    my $self = shift;
    my @params = $self->vars;
    $self->_db->begin_work;
    if($self->new_precondition(@params))
    {
        $self->run_sql($self->insert(@params));
        $self->_db->commit;
        return 'ok';
    }
    else
    {
        $self->_db->rollback;
        return 'error';
    }
}

sub do_delete()
{
    my $self = shift;
    my @params = $self->vars;
    $self->_db->begin_work;
    $self->run_sql($self->delete(@params));
    $self->_db->commit;
    return 'ok';
}

sub do_modify
{
    my $self = shift;
    my @params = $self->vars;

    # Split the parameters into two lists: one with the old values
    # (used to delete the existing record) and one with the new values
    # (used to create a new record).
    my @old_params = ();
    my @new_params = ();
    while( @params )
    {
        my $name  = shift @params;
        my $value = shift @params;
        if($name =~ /:old$/)
        {
            $name =~ s/:old$//;
            push @old_params, $name, $value;
        }
        else
        {
            push @new_params, $name, $value;
        }
    }

    $self->_db->begin_work;
    $self->run_sql($self->delete(@old_params));
    $self->run_sql($self->insert(@new_params));
    $self->_db->commit;
    return 'ok';
}

sub do_list
{
    my $self = shift;
    my ($sql_callback,$output_callback,@params) = @_;
    my ($sql,$params,$post_process) = $self->list(@params);

    $sql = $sql_callback->($sql);

    my $sth = $self->run_sql_command($sql,@{$params});
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


sub run_sql
{
    my $self = shift;
    while(my $sql = shift)
    {
        my $params = shift;
        $self->run_sql_command($sql,@{$params});
    }
}

sub run_sql_once
{
    my $self = shift;
    my $sth = $self->run_sql_command(@_);
    return undef if not defined $sth;
    my $val = $sth->fetchrow_arrayref->[0];
    $sth->finish();
    $sth = undef;
    return $val;
}

sub run_sql_command
{
    my $self = shift;
    my $cmd = shift;
    my $sth = $self->_db->prepare($cmd);

    if(!$sth || !$sth->execute(@_))
    {
        use Carp;
        confess("$cmd(".join(',',@_)."): ".$self->_db->errstr);
    }

    warn "$cmd(".join(',',@_).")\n";
    return $sth;
}

sub _c($)
{
    my $t = shift;
    return undef if not defined $t;
    $t =~ s/^\s+//; $t =~ s/\s+$//;
    $t =~ s/\s+/ /;
    return $t if $t ne '';
    return undef;
}

sub vars()
{
    my $self = shift;
    my @params = $self->_cgi->Vars;
    my @res = ();
    while( @params )
    {
        my $key = shift @params;
        my $value = _c(shift @params);
        push @res, $key, $value;
    }
    return @res;
}

sub run_as_json
{
    our $self = shift;
    my $result = shift;
    my @params = $self->vars;
    our %params = @params;

    our %json_result = ();

    if($self->method eq 'query')
    {
        our @json_rows = ();

        my $sql_callback = sub
        {
            my $sql = shift;
            $sql .= " LIMIT $params{_limit}",
            $json_result{limit} = $params{_limit}
                if exists $params{_limit}
                and defined $params{_limit};
            $sql .= " OFFSET $params{_offset}",
            $json_result{offset} = $params{_offset}
                if exists $params{_offset}
                and defined $params{_offset};
            return $sql;
        };

        my $json_callback = sub
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

            push @json_rows, {%values};
        };

        my $nb_rows = $self->do_list($sql_callback,$json_callback,@params);
        $json_result{total_rows} = $nb_rows;
        $json_result{rows} = [@json_rows];
    }
    else
    {
        $json_result{result} = $result;
    }

    print $self->_cgi->header(-type=>'text/json',-charset=>'utf-8');

    use JSON;
    print objToJson({%json_result});
}

sub run()
{
    my $self = shift;

    my $method = $self->method;

    my $result = 'ok';
    # This would need an eval() to collect error messages,
    # unless I rewrite the code to work properly.
    $result = $self->do_delete if $method eq 'delete';
    $result = $self->do_insert if $method eq 'insert';
    $result = $self->do_modify if $method eq 'modify';

    $self->run_as_json($result);
}

1;

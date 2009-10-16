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
    my ($cgi,$db) = @_;
    $self->{_cgi}      = $cgi;
    $self->{_db}       = $db;
}

sub class { my $c = ref(shift); $c =~ s/^.*:://; return $c; }

sub _cgi { shift->{_cgi} }
sub _db  { shift->{_db} }

sub method
{
    my $self = shift;
    my $method = $self->_cgi->param('_method');
    $method = 'list' if not defined $method;
    return $method;
}

sub do_input
{
    my $self = shift;
    my @form = $self->form();

    print
        $self->_cgi->start_form(-method=>'POST'),
        $self->_cgi->hidden(-name=>'_class',-default=>$self->class,-force=>1);

    print
        '<table class="ccn_form">';

    while( my $name = shift @form )
    {
        print '<tr class="line">';

        my $type = shift @form;
        my $label = $name;
        $label =~ s/_/ /g;
        print
            '<th class="label">',
                '<label for="'.lc($name).'">'.$label.'</label>',
            '</th>';

        print
            '<td class="value">';

        # Save the previous value for modifications.
        my $default = $self->_cgi->param(lc($name));
        print $self->_cgi->hidden(-name=>lc($name).':old',-default=>$default,-force=>1);

        if( ref($type) eq 'ARRAY' )
        {
            # Take every other field, in the same order.
            my @values = @{$type};
            my %values2 = @values;
            my @values2;
            while( @values )
            {
                push @values2, shift @values;
                shift @values;
            }

            # Print an option group.
            print $self->_cgi->popup_menu(
                -name => lc($name),
                -default=> $default,
                -values => \@values2,
                -labels => \%values2,
            );
        }
        else
        {
            my @extras = ();
            if($type eq 'ip')
            {
                @extras = (
                    -dojoType => 'dijit.form.ValidationTextBox',
                    -regExp => '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}',
                    -invalidMessage => 'Need IP Address',
                );
            }

            # Print a simple textfield.
            print $self->_cgi->textfield(
                -name => lc($name),
                -default => $default,
                -value => '',
                -size => 16,
                -maxlength => 255,
                @extras
            );
        }
        print
            '</td>';

        print '</tr>'; # line
    }

    print
        '</table>';

    if($self->method eq 'input_modify')
    {
        print $self->_cgi->hidden(-name=>'_method',-default=>'modify',-force=>1);
        print $self->_cgi->submit('Modify');
        print $self->_cgi->reset();
    }
    else
    {
        print $self->_cgi->hidden(-name=>'_method',-default=>'insert',-force=>1);
        print $self->_cgi->submit('Insert');
        print $self->_cgi->reset();
    }

    print $self->_cgi->end_form;
}

sub do_form
{
    our $self = shift;
    my @params = $self->vars;
    our %params = @params;

    my $sql_callback = sub
    {
        my $sql = shift;
        $sql .= " LIMIT $params{_limit}"
            if exists $params{_limit}
            and defined $params{_limit};
        $sql .= " OFFSET $params{_offset}"
            if exists $params{_offset}
            and defined $params{_offset};
        return $sql;
    };

    our $started = 0;

    sub html_start($)
    {
        my ($names) = @_;
        print '<table class="ccn_report"><tbody><tr>';
        print '<th class="ccn_action">Modify</td>';
        print '<th class="ccn_action">Delete</td>';
        for my $name (@{$names})
        {
            my $display_name = $name;
            $display_name =~ s/[!*]$//;
            $display_name =~ s/_/ /;
            print qq(<th class="ccn_report">$display_name</th>)
                unless $name =~ /\*$/; # hide
        }
        print "</tr>\n";
        $started = 1;
    }

    my $html_callback = sub
    {
        my ($content,$names) = @_;
        # No content?
        return unless defined $content and $content;
        #
        html_start($names) if not $started;

        print '<tr>';

        my $form = '';
        my $display = '';

        my @content = @{$content};
        for my $name (@{$names})
        {
            my $value = shift @content;
            my $display_name = $name;
            $display_name =~ s/[!*]$//;
            $display .=
                '<td class="ccn_report">'.
                    (defined $value ? $value : '').
                '</td>'
                unless $name =~ /\*$/;
            $form .= $self->_cgi->hidden(-name=>lc($display_name),-default=>$value,-force=>1)
                unless $name =~ /!$/; # no value
        }

        print
            '<td class="ccn_action">',
                $self->_cgi->start_form(-method=>'POST').
                $form,
                $self->_cgi->hidden(-name=>'_class', -default=>$self->class,  -force=>1),
                $self->_cgi->hidden(-name=>'_method',-default=>'input_modify',-force=>1),
                # $self->_cgi->submit('Modify'),
                $self->_cgi->image_button(-name=>'_apply',-src=>'ccn_icons/modify.png',-align=>'MIDDLE'),
                $self->_cgi->end_form,
            '</td>';

        print
            '<td class="ccn_action">',
                $self->_cgi->start_form(-method=>'POST').
                $form,
                $self->_cgi->hidden(-name=>'_class', -default=>$self->class,-force=>1),
                $self->_cgi->hidden(-name=>'_method',-default=>'delete',    -force=>1),
                # $self->_cgi->submit('Delete'),
                $self->_cgi->image_button(-name=>'_apply',-src=>'ccn_icons/delete.png',-align=>'MIDDLE'),
                $self->_cgi->end_form,
            '</td>';

        print $display;

        print "</tr>\n";
    };
    sub html_end
    {
        print '</tbody></table>';
    }

    my $nb_rows = $self->do_list($sql_callback,$html_callback,@params);

    html_end() if $started;

    # YYY This should be done using
    # http://dojotoolkit.org/book/book-dojo/part-3-javascript-programming-dojo-and-dijit/using-dojo-data/available-stores/dojox-d
    # and
    # http://dojotoolkit.org/book/dojo-book-0-9/docx-documentation-under-development/grid
    # but let's wait until the API stabilize and Grid makes it into Dijit.
    my $_limit = $params{_limit};
    my $_offset = $params{_offset};
    $_offset = 0 if not defined $_offset;

    if(defined $_limit)
    {
        # Print a "first" button ...
        if($_offset > $_limit)
        {
            print
                $self->_cgi->start_form(-method=>'POST'),
                $self->_cgi->hidden(-name=>'_class', -default=>$self->class,  -force=>1),
                $self->_cgi->hidden(-name=>'_method',-default=>'',-force=>1),
                $self->_cgi->hidden(-name=>'_offset',-default=>0,-force=>1),
                $self->_cgi->hidden(-name=>'_limit',-default=>$_limit,-force=>1),
                $self->_cgi->hidden(-name=>'_tab', -default=>2,  -force=>1),
                $self->_cgi->image_button(-name=>'_apply',-src=>'ccn_icons/go-first.png'),
                $self->_cgi->end_form;
        }
        else
        {
            print q(<img src="ccn_icons/blank.png" />);
        }

        # Print a "previous" button ...
        if($_offset > 0)
        {
            my $prev = $_offset - $_limit;
            $prev = 0 if $prev < 0;
            print
                $self->_cgi->start_form(-method=>'POST'),
                $self->_cgi->hidden(-name=>'_class', -default=>$self->class,  -force=>1),
                $self->_cgi->hidden(-name=>'_method',-default=>'',-force=>1),
                $self->_cgi->hidden(-name=>'_offset',-default=>$prev,-force=>1),
                $self->_cgi->hidden(-name=>'_limit',-default=>$_limit,-force=>1),
                $self->_cgi->hidden(-name=>'_tab', -default=>2,  -force=>1),
                $self->_cgi->image_button(-name=>'_apply',-src=>'ccn_icons/go-previous.png'),
                $self->_cgi->end_form;
        }
        else
        {
            print q(<img src="ccn_icons/blank.png" />);
        }

        if($_offset+1 < $_offset+$nb_rows)
        {
            print " ".($_offset+1)." .. ".($_offset+$nb_rows)." ";
        }

        # Print a "next" button
        if(defined $nb_rows and $nb_rows == $_limit)
        {
            print
                $self->_cgi->start_form(-method=>'POST'),
                $self->_cgi->hidden(-name=>'_class', -default=>$self->class,  -force=>1),
                $self->_cgi->hidden(-name=>'_method',-default=>'',-force=>1),
                $self->_cgi->hidden(-name=>'_offset',-default=>($_offset+$nb_rows),-force=>1),
                $self->_cgi->hidden(-name=>'_limit',-default=>$_limit,-force=>1),
                $self->_cgi->hidden(-name=>'_tab', -default=>2,  -force=>1),
                $self->_cgi->image_button(-name=>'_apply',-src=>'ccn_icons/go-next.png'),
                $self->_cgi->end_form;
        }
        else
        {
            print q(<img src="ccn_icons/blank.png" />);
        }
    }
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

sub run_as_html()
{
    my $self = shift;

    my $title = ucfirst($self->class).' '.ucfirst($self->method);

    my $dojo_code = <<JAVASCRIPT;
    dojo.require("dojo.parser");
    dojo.require("dijit.layout.ContentPane");
    dojo.require("dijit.layout.TabContainer");
    dojo.require("dijit.form.Button");
    dojo.require("dijit.form.ValidationTextBox");
    dojo.require("dijit.form.NumberTextBox");
JAVASCRIPT

    print
        $self->_cgi->header,
        <<HTML;
<html>
    <head>
    <title>${configuration::sitename}</title>
        <style type="text/css">
            \@import "js/dojo/dijit/themes/tundra/tundra.css";
            \@import "js/dojo/dojo/resources/dojo.css";
            \@import "${configuration::theme}default.css";
        </style>
        <script type="text/javascript" src="js/dojo/dojo/dojo.js" djConfig="parseOnLoad: true"></script>
        <script type="text/javascript">
            $dojo_code
        </script>
    </head>
    <body class="tundra">
HTML

    print q(<div id="mainTabContainer" dojoType="dijit.layout.TabContainer" style="width:auto;height:100%;">);

    my $tab = $self->_cgi->param('_tab');
    $tab = 1 if not defined $tab or int($tab) < 1;

        print q(<div id="view" dojoType="dijit.layout.ContentPane" title="Manage").($tab == 1?q( selected="true"):'').q(>);
            print '<div class="input">';
            $self->do_input;
            print '</div>';
        print q(</div>);

        unless( $self->_cgi->param('_quick') )
        {
            print q(<div id="list" dojoType="dijit.layout.ContentPane" title="List").($tab == 2?q( selected="true"):'').q(>);
                print '<div class="form">';
                $self->do_form;
                print '</div>';
            print q(</div>);

            print q(<div id="help" dojoType="dijit.layout.ContentPane" title="Help">);
                print q(<div class="doc">);
                print $self->doc;
                print '</div>';
            print q(</div>);
        }

    print q(</div>);

    print
        $self->_cgi->end_html;
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
    my $as = $self->_cgi->param('_as');
    $as = 'html' if not defined $as;

    my $result = 'ok';
    # This would need an eval() to collect error messages,
    # unless I rewrite the code to work properly.
    $result = $self->do_delete if $method eq 'delete';
    $result = $self->do_insert if $method eq 'insert';
    $result = $self->do_modify if $method eq 'modify';

    $self->run_as_html() if $as eq 'html';
    $self->run_as_json($result) if $as eq 'json';
    $self->run_as_tab()  if $as eq 'tab';
}

1;

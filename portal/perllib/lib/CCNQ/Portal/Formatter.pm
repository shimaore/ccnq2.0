package CCNQ::Portal::Formatter;
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
use strict; use warnings;

sub format
{
  our ($cgi,$format,$columns,$callback) = @_;

  if(defined $format && $format eq 'tab')
  {
    my $content = '';
    $content .= join("\t", @{$columns})."\n";
    my $rows = 0;
    while(my $row = $callback->($rows))
    {
      $content .= join("\t",map { (exists $row->{value}->{$_} && defined $row->{value}->{$_}) ? $row->{value}->{$_} : '' } @{$columns})."\n";
      $rows ++;
    }
    return ['tab',$cgi->header(-type=>'text/tab-separated-values',-charset=>'utf-8',-attachment=>'export.csv'),$content];
  }

  if(defined $format && $format eq 'inline')
  {
    my $content = '';
    my $rows = 0;
    while(my $row = $callback->($rows))
    {
      $content .= '<table><tbody>';
      $content .= join('',map { "<tr><th>$_</th><td>".((exists $row->{value}->{$_} && defined $row->{value}->{$_}) ? $row->{value}->{$_} : '').'</td></tr>' } @{$columns})."\n";
      $content .= '</tbody></table>';
      $rows ++;
    }
    $content .= "\n";
    return ['inline',$cgi->header(-charset=>'utf-8'),$content];
  }
  
  # For JSON we return the row data since it will be output as JSON later.
  if(defined $format && $format eq 'json')
  {
    my $content = {};
    my $rows = 0;
    $content->{columns} = $columns;
    while(my $row = $callback->($rows))
    {
      $content->{rows}->[$rows] = {map { (exists $row->{value}->{$_} && defined $row->{value}->{$_}) ? ($_ => $row->{value}->{$_}) : () } @{$columns} };
      $rows ++;
    }
    $content->{length} = $rows;
    return ['inline',undef,$content];
  }

  my $html = '<table class="report"><tbody>';
  $html .=  '<tr>'.join('', map { "<th>$_</th>" } @{$columns}).'</tr>';
  my $rows = 0;
  while(my $row = $callback->($rows))
  {
    # If there is a "href" map, we use it to offer direct links to other parts of the site.
    # This breaks the modularization (for example, Portal::Number must know about the location
    # of a target URL for a number). There are probably ways around it.
    # Also we set a target so that if the rendering is "iframe", the links point to the same window/tab.
    $html .=
        (exists $row->{rowclass} ? qq(<tr class="$row->{rowclass}">) : '<tr>').
        join('', map {
          my $value = (exists $row->{value}->{$_} && defined $row->{value}->{$_}) ? $row->{value}->{$_} : '';
          (exists $row->{class}->{$_} ? '<td class="'.$row->{class}->{$_}.'">' : '<td>').
          (exists $row->{href}->{$_} ? $cgi->a({-href=>$row->{href}->{$_},-target=>'_parent'},$value) : $cgi->span($value))
          .'</td>'
        } @{$columns} )
        ."</tr>\n";
   $rows ++;
  }
  $html .= '</tbody></table>'."\n";
  return ['html',$cgi->header(-charset=>'utf-8').$cgi->start_html(-title=>"${rows} rows",-style=>{'src'=>'/styles.css'},-class=>'report'),$html];
};


sub make_form
{
  our $cgi = shift;

  my $f = shift;
  my @f = (@{$f});

  my $no_submit = shift || 0;

  my %out = (
    start_form => '',
    submit     => '',
    end_form   => '',
  );

  our @block = ();
  while(@f)
  {
    my $name = shift @f;
    our $v   = shift @f;
    return 'Internal error' if !defined($name) || !defined($v);

    $out{form} .= make_form($cgi,$v,1), next if $name eq 'form';

    # Simply passes the value through (used for _legend)
    $out{$name} = $v, next if $name =~ /^_/;

    sub _bl
    {
      # Parameters should be: label, input
      if($v->{nonewline} || $#block >= 0)
      {
        push @block, [@_];
      }
      my $res = '';
      if(!$v->{nonewline})
      {
        if($#block >= 0)
        {
          $res =
            q(<table><tbody>).
            q(<tr>).join('',map { qq(<td>$_->[0]</td>) } @block).q(</tr>).
            q(<tr>).join('',map { qq(<td>$_->[1]</td>) } @block).q(</tr>).
            q(</table></tbody>);
          @block = ();
        }
        else
        {
          $res = q(<div>).join(' ',@_).q(</div>);
        }
      }
      return $res;
    }

    die "$name has invalid description" unless ref($v) eq 'HASH';

    my $label =
      qq(<label>).($v->{label}||'').
      ($v->{required} ? '<span class="form-required" title="This field is required.">*</span>' : '').
      qq(</label>).($v->{nobreak} ? '&nbsp;' : '<br/>');

    my $d = $v->{values};
    if(defined $d)
    {
      $out{form} .= _bl($label,$cgi->textfield(-force=>1,-name=>$name,-value=>$d,-default=>$d,-size=>$v->{size},-maxlength=>$v->{maxlength})) if ref($d) eq '';
      $out{form} .= _bl($label,$cgi->popup_menu(-force=>1,-name=>$name,-values=>$d,-default=>$v->{default})) if ref($d) eq 'ARRAY';
      $out{form} .= _bl($label,$cgi->popup_menu(-force=>1,-name=>$name,-values=>[sort { $d->{$a} cmp $d->{$b} } keys %{$d}],-labels=>$d,-default=>$v->{default})) if ref($d) eq 'HASH';
    }
    else
    {
      # Use _type as the type of field; defaults to "textfield".
      my $type = exists $v->{_type} ? $v->{_type} : 'textfield';

      $out{form} .= {
        textfield => sub { _bl($label,$cgi->textfield(-force=>1,-name=>$name,-value=>$v->{default},-default=>$v->{default},-size=>$v->{size},-maxlength=>$v->{maxlength})); },
        hidden    => sub { $cgi->hidden(-force=>1,-name=>$name,-default=>$v->{default},-value=>$v->{default}); },
        checkbox  => sub { _bl($label,$cgi->checkbox(-force=>1,-name=>$name,-default=>$v->{default},-value=>$v->{value},-label=>'',-checked=>$v->{checked})); },
      }->{$type}->();
    }
  };

  unless($no_submit)
  {
    $out{start_form} ||= $cgi->start_form(-action=>$out{_action});
    $out{submit}     ||= $cgi->submit();
    $out{end_form}   ||= $cgi->end_form();
  };

  return qq(\n<fieldset class="ui-widget-content"><legend>$out{_legend}</legend>$out{start_form}\n<div>$out{form}</div>\n<div>$out{submit}</div>\n$out{end_form}</fieldset>);
}

sub pp
{
  my $v = shift;
  if(ref($v) eq '')
  {
    return qq("$v");
  }
  if(ref($v) eq 'ARRAY')
  {
    return '[ '.join(', ', map { pp($_) } @{$v}).' ]';
  }
  return '{ '.join(', ', map { qq("$_": ).pp($v->{$_}) } sort keys %{$v}).' }';
}

1;

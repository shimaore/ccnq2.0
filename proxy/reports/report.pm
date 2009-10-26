package CCNQ::Proxy::report;
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

sub list_of_timestamps
{
    opendir(my $dh, '/var/log/billing') or die "Can't open /var/log/billing";
    my @timestamps = sort { $b cmp $a } grep { /^\d{8}-\d{4}$/ } readdir($dh);
    close($dh);
    return @timestamps;
}

sub insert
{
}

# sub run_as_html { my $self = shift; print $self->_cgi->header().$self->_cgi->start_html(); $self->do_form(); print $self->_cgi->end_html; }
sub run_as_json { my $self = shift; print $self->_cgi->header(-type=>'text/json',-charset=>'utf-8'); $self->do_form(); }
sub run_as_tab  { my $self = shift; print $self->_cgi->header(-type=>'text/tab-separated-values',-charset=>'utf-8',-attachment=>'export.csv'); $self->do_form(); }

#
#   _do_command_table($command,@command_args)
#

sub _do_command_table
{
    my $self = shift;
    my $command = shift;
    my $command_args = join(' ', map { qq("$_") } @_);

    my @params = $self->vars;
    our %params = @params;

    my $as = $params{_as};
    $as = 'html' if !defined($as) || !grep { $_ eq $as } (qw(html tab json));

    my @servers = ($self->list_of_servers);
    my $want_server  = $params{server};
    if(defined $want_server && $want_server ne '')
    {
      die 'No such server' unless grep { $_ eq $want_server } @servers;
      @servers = ($want_server);
    }

    # START
    print({ 
     html => qq(<table class="ccn_report">\n),
     tab  => '',
     json => "[\n",
    }->{$as});
    # /START

    our @columns = ();

    for my $server (@servers)
    {
      my $ssh_server = $server;

      my $timestamp      = $params{timestamp};
      my $files;
      # Realtime
      if(not defined $timestamp or $timestamp eq '')
      {
        $timestamp = '';
        $files = '/var/log/opensips/acc_*.log';
      }
      # Non-realtime
      else
      {
        $ssh_server = 'localhost';
        my ($name,$port) = split(/:/,$server);
        $files = "/var/log/billing/$timestamp/server-$name.log.bz2";
      }

      # XXX This assumes all servers in the cluster have the same "install_dir".
      my $shell_command =
        qq(${configuration::install_dir}/CCNQ/Proxy/bin/${command} "${server}" "${timestamp}" ${command_args});

      if( ${files} =~ /bz2$/ )
      {
        $shell_command = "bzcat ${files} | ${shell_command}";
      }
      else
      {
        $shell_command = "${shell_command} ${files}";
      }


      if( ${ssh_server} eq 'localhost' or ${ssh_server} =~ /^127\.\d{1,3}\.\d{1,3}\.\d{1,3}$/ )
      {
        # Nothing to do.
      }
      else
      {
        my ($ssh_server_name,$ssh_server_port) = split(/:/,$ssh_server);
        $ssh_server_port = 22 if not defined $ssh_server_port;
        $shell_command = qq(ssh -p '${ssh_server_port}' '${ssh_server_name}' '${shell_command}');
      }

      warn($shell_command);
      open my $fh, '-|', $shell_command or die $!;

      while(<$fh>)
      {
        chomp;
        my @fields = split(/\t/);
        if($fields[0] =~ /^\s/)
        {
          # HEADER
          if($#columns == -1)
          {
            @columns = @fields;
            map { s/^\s+//; s/\s+$//; s/\s+/ /; } @columns;
          }
          print({
            html => sub { '<tr>'.join('', map { qq(<th class="ccn_report">$_</th>)} @columns )."</tr>\n" },
            tab  => sub { join("\t", @columns)."\n" },
            json => sub { "\n" },
          }->{$as}->());
          # /HEADER
        }
        else
        {
          # DATA
          print({
            html => sub { '<tr>'.join('', map { s{\(([^)]+)\)}{<br><small>$1</small>}; qq(<td align="char" char="." class="ccn_report">$_</td>)} @fields )."</tr>\n" },
            tab  => sub { join("\t", @fields)."\n" },
            json => sub { my %json_result = map { $columns[$_] => $fields[$_] } (0..$#columns); objToJson({%json_result})."\n" },
          }->{$as}->());
          # /DATA
        }
      }
      close($fh) or die $!;
    }

    # STOP
    print({
      html => "</table>\n",
      tab  => '',
      json => " ]\n",
    }->{$as});
    # /STOP
}

1;

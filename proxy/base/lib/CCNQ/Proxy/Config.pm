package CCNQ::Proxy::Config;
# clean.pl -- merge OpenSIPS configuration fragments
# Copyright (C) 2009  Stephane Alnet
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
use strict; use warnings;
use Logger::Syslog;
use Memoize;

=pod

  compile_cfg
    Build OpenSIPS configuration from fragments.

  compile_sql
    Build SQL configuration from fragments.

  clean_cfg
    Rename route statements and prune unavailable ones.

=cut

sub clean_cfg;

sub recipe_for {
  my ($base_dir,$recipe_name) = @_;

  my $recipe_file = File::Spec->catfile($base_dir,"${recipe_name}.recipe");

  my @recipe = ();

  open(my $fh,'<',$recipe_file) or die "$recipe_file: $!";
  while(<$fh>) {
    chomp;
    next if /^#/;
    push @recipe, $_;
  }
  close($fh) or die "$recipe_file: $!";

  return @recipe;
}
memoize('recipe_for');

sub compile_cfg {
  my ($base_dir,$recipe_name) = @_;

  my @recipe = recipe_for($base_dir,$recipe_name);

  my $result = <<EOH;
#
# Automatically generated for recipe ${recipe_name}
#
EOH

  for my $extension qw(variables modules cfg) {
    for my $building_block (@recipe) {
      my $file = File::Spec->catfile($base_dir,'src',"${building_block}.${extension}");
      if( -e $file ) {
        $result .= "\n## ---  Start ${file}  --- ##\n\n";
        $result .= CCNQ::Install::content_of($file);
        $result .= "\n## ---  End ${file}  --- ##\n\n";
      }
    }
  }
  return clean_cfg($result);
}

sub compile_sql {
  my ($base_dir,$recipe_name) = @_;

  my @recipe = recipe_for($base_dir,$recipe_name);

  my $result = '';
  my $extension = 'sql';
  for my $building_block (@recipe) {
    my $file = File::Spec->catfile($base_dir,'src',"${building_block}.${extension}");
    if( -e $file ) {
      $result .= CCNQ::Install::content_of($file);
    }
  }
  return $result;
}

sub clean_cfg {
  my $t = shift;

  my @available = ($t =~ m{ \b route \[ ([^\]]+) \] }gsx);
  my %available = map { $_ => 0 } @available;
  $t =~ s{ \b route \( ([^\)]+) \) }{
    exists($available{$1})
      ? ($available{$1}++, "route($1)")
      : (warning("Removing unknown route($1)"),"")
  }gsxe;

  my @unused = grep { !$available{$_} } sort keys %available;
  warning( q(Unused routes: ).join(', ',@unused) ) if @unused;

  my @used = grep { $available{$_} } sort keys %available;

  my $route = 0;
  my %route = map { $_ => ++$route } sort @used;

  warning("Found $route routes");

  $t =~ s{ \b route \( ([^\)]+) \) \s* ([;\#\)]) }{ "route($route{$1}) $2" }gsxe;
  $t =~ s{ \b route \[ ([^\]]+) \] \s* ([\{\#]) }{ "route[$route{$1}] $2" }gsxe;

  $t .= "\n".join('', map { "# route($route{$_}) => route($_)\n" } sort keys %route);

  # Macro pre-processing
  my %defines = ();
  $t =~ s{ \#define \s+ (\w+) \b }{ $defines{$1} = 1, '' }gsxe;
  $t =~ s{ \#ifdef \s+ (\w+) \b (.*?) \#endifdef \s+ \1 \b }{ exists($defines{$1}) ? $2 : '' }gsxe;
  $t =~ s{ \#ifnotdef \s+ (\w+) \b (.*?) \#endifnotdef \s+ \1 \b }{ exists($defines{$1}) ? '' : $2 }gsxe;

  warning("Unmatched rule $1 $2") if $t =~ m{\#(ifdef|ifnotdef|endifdef|endifnotdef) \s+ (\w+) }gsx;
  return $t;
}

=pod

  configure_opensips
    Subtitute configuration variables in a complete OpenSIPS configuration file
    (such as one generated by compile_cfg).

=cut

use CCNQ::Proxy::Configuration;
use IO::Scalar;

sub configure_opensips {
  my ($model) = @_;

  my %values = CCNQ::Proxy::Configuration::parameters();

  my $accounting_pattern   = '#IF_ACCT_'.uc($configuration::accounting);
  my $authenticate_pattern = '#IF_AUTH_'.uc($configuration::authenticate);

  # End of parameters

  my $template_text = compile_cfg(CCNQ::Proxy::opensips_base_lib,$model);
  my $sql_text      = compile_sql(CCNQ::Proxy::opensips_base_lib,$model);

  my $template = new IO::Scalar \$template_text;

  my $cfg_text = '';
  while(<$template>)
  {
      s/\$\{([A-Z_]+)\}/defined $values{$1} ? $values{$1} : (warning("Undefined $1"),'')/eg;
      s/^\s*${accounting_pattern}//;
      s/^\s*${authenticate_pattern}//;
      s/^\s*#IF_USE_NODE_ID// if $configuration::node_id;
      s/^\s*#USE_PROXY_IP\s*// if $configuration::sip_host;
      $cfg_text .= $_;
  }

  # Save the configurations to temp files
  my $cfg_file = new File::Temp;
  my $sql_file = new File::Temp;
  print_to($cfg_file,$cfg_text);
  print_to($sql_file,$sql_text);

  # Move the temp files to their final destinations
  info("Installing new configuration");
  CCNQ::Install::_execute('cp',$cfg_file,CCNQ::Proxy::runtime_opensips_cfg);
  CCNQ::Install::_execute('cp',$sql_file,CCNQ::Proxy::runtime_opensips_sql);

  # Print out some info on how to use the SQL file.
  my $runtime_opensips_sql = CCNQ::Proxy::runtime_opensips_sql;
  my $db_name = CCNQ::Proxy::Configuration::db_name;
  my $db_login = CCNQ::Proxy::Configuration::db_login;
  my $db_password = CCNQ::Proxy::Configuration::db_password;
  info(<<TXT);
Please run the following commands:
mysql <<SQL
  CREATE DATABASE ${db_name};
  CONNECT ${db_name};
  CREATE USER ${db_login} IDENTIFIED BY '${db_password}';
  GRANT ALL ON ${db_name}.* TO ${db_login};
SQL

mysql ${db_name} < ${runtime_opensips_sql}

TXT

}

1;
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
  return clean($result);
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
  $t =~ s{ \#define \s+ (\w+) \b }{ $defines{$1} = 1 }gsxe;
  $t =~ s{ \#ifdef \s+ (\w+) \b (.*?) \#endifdef \s+ \1 \b }{ exists($defines{$1}) ? $2 : '' }gsxe;
  $t =~ s{ \#ifnotdef \s+ (\w+) \b (.*?) \#endifnotdef \s+ \1 \b }{ exists($defines{$1}) ? '' : $2 }gsxe;

  warning("Unmatched rule $1 $2") if $t =~ m{\#(ifdef|ifnotdef|endifdef|endifnotdef) \s+ (\w+) }gsx;
  return $t;
}

1;
package CCNQ;

=head1 NAME

CCNQ - Distribution for ccnq2.0

=head1 SYNOPSIS

Currently this module only exists to make File::ShareDir happy.
Eventually most of the CCNQ::Install code should probably be migrated here.

=head1 AUTHOR

Stephane Alnet <stephane@shimaore.net>

=head1 LICENSE

Copyright (C) 2009  Stephane Alnet

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 3
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

use 5.008;
use vars qw{$VERSION};

our $VERSION = '0.04';

=head1 DESCRIPTION

=head2 CCN

Returns the directory where the local configuration information is kept.

=cut

use constant CCN => q(/etc/ccn);

# Source path resolution

=head2 SRC

Returns the path of the shared directory as it is installed on the local machine.

=cut

use File::ShareDir;

use constant CCNQ_MAKEFILE_MODULE_NAME => 'CCNQ';
use constant SRC => File::ShareDir::dist_dir(CCNQ_MAKEFILE_MODULE_NAME);


'CCNQ';

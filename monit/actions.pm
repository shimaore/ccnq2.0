# monit/actions.pm

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

use CCNQ::Install;
use CCNQ::Util;
use CCNQ::AE;
use File::Spec;

use constant::defer monit_directory =>
  sub { File::Spec->catfile(CCNQ::Install::SRC,qw( monit )) };
use constant monit_target => '/etc/monit';

{
  install => sub {
    my ($params,$context,$mcv) = @_;
    for my $file qw( couchdb.monitrc freeswitch.monitrc local.monitrc monitrc opensips.monitrc ) {
      my $src = File::Spec->catfile(monit_directory,$file);
      my $content = CCNQ::Util::content_of($src);
      $content =~ s/__HOST__/CCNQ::Install::host_name()/ge;
      $content =~ s/__DOMAIN__/CCNQ::Install::domain_name()/ge;
      my $dst = File::Spec->catfile(monit_target,$file);
      CCNQ::Util::print_to($dst,$content);
    }

    $mcv->send(CCNQ::AE::SUCCESS);
  },

}
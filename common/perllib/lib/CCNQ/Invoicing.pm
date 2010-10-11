package CCNQ::Invoicing;
# Copyright (C) 2010  Stephane Alnet
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation; either version 3
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
use strict; use warnings;

use CCNQ;
use CCNQ::Util;
use File::Spec;
use File::Path;

use Logger::Syslog;

# Update crontab to insert crontab_daily
sub crontab_update {
  my $crontab_line = <<CRON;
SHELL=/bin/bash
PATH=/bin:/usr/bin:/usr/local/bin
0 23 * * *   nice -n 20 ccnq2_crontab_invoicing
CRON
  my $crontab_file = File::Spec->catfile(CCNQ::CCN,'ccnq2_crontab_daily.crontab');

  CCNQ::Util::print_to($crontab_file,$crontab_line);
  CCNQ::Util::execute(qq(/usr/bin/crontab "${crontab_file}"));
}


use AnyEvent;
use AnyEvent::CouchDB;
use CCNQ::CouchDB;

use constant::defer invoicing_uri => sub {
  CCNQ::Install::make_couchdb_uri_from_server(CCNQ::Install::cluster_fqdn('invoicing'))
};
use constant invoicing_db => 'invoicing';

use constant js_report_by_month => <<'JAVASCRIPT';
  function (doc) {
    emit([doc.account,doc.year+"",doc.month+""],null);
  }
JAVASCRIPT

use constant invoicing_designs => {
  report => {
    language => 'javascript',
    views    => {
      monthly => {
        map => js_report_by_month,
      },
      # other views here
    },
  },
};

sub install {
  my ($params,$context) = @_;
  return CCNQ::CouchDB::install(invoicing_uri,invoicing_db,invoicing_designs);
}

sub insert {
  my ($record) = @_;
  return CCNQ::CouchDB::update_cv(invoicing_uri,invoicing_db,$record);
}

sub retrieve {
  my ($params) = @_;
  return CCNQ::CouchDB::retrieve_cv(invoicing_uri,invoicing_db,$params);
}

sub view {
  my ($params) = @_;
  return CCNQ::CouchDB::view_cv(invoicing_uri,invoicing_db,$params);
}

1;

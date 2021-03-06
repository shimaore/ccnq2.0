# Tests for inclusion of different CCQN modules.

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
use Test::More;

require_ok( 'CCNQ' );

require_ok( 'CCNQ::Object' );
require_ok( 'CCNQ::MathContainer' );
require_ok( 'AnyEvent::Watchdog::Util' );

require_ok( 'CCNQ::B2BUA' );
require_ok( 'CCNQ::B2BUA::Process' );

require_ok( 'CCNQ::HTTPD' );

require_ok( 'CCNQ::Install' );
require_ok( 'CCNQ::Util' );

require_ok( 'CCNQ::AE' );
require_ok( 'CCNQ::AE::Run' );
require_ok( 'CCNQ::API' );
require_ok( 'CCNQ::API::Server' );
require_ok( 'CCNQ::Billing' );
require_ok( 'CCNQ::Billing::Account' );
require_ok( 'CCNQ::Billing::Bucket' );
require_ok( 'CCNQ::Billing::Plan' );
require_ok( 'CCNQ::Billing::Rating' );
require_ok( 'CCNQ::Billing::Table' );
require_ok( 'CCNQ::Billing::User' );
require_ok( 'CCNQ::CDR' );
require_ok( 'CCNQ::CouchDB' );
require_ok( 'CCNQ::CouchDB::CodeStore' );
require_ok( 'CCNQ::Invoicing' );
require_ok( 'CCNQ::Invoicing::Record' );
require_ok( 'CCNQ::Invoicing::Counts' );
require_ok( 'CCNQ::Invoicing::Summarize' );
require_ok( 'CCNQ::Invoicing::Daily' );
require_ok( 'CCNQ::Manager' );
require_ok( 'CCNQ::Manager::CodeStore' );
require_ok( 'CCNQ::MediaProxy' );
require_ok( 'CCNQ::Monit' );
require_ok( 'CCNQ::Provisioning' );
require_ok( 'CCNQ::Trace' );
require_ok( 'CCNQ::Trie' );
require_ok( 'CCNQ::Upgrade' );
require_ok( 'CCNQ::Restart' );
require_ok( 'CCNQ::XMPPAgent' );

require_ok( 'CCNQ::Proxy' );
require_ok( 'CCNQ::Proxy::Base' );
require_ok( 'CCNQ::Proxy::Config' );
require_ok( 'CCNQ::Proxy::Configuration' );
require_ok( 'CCNQ::Proxy::domain' );
require_ok( 'CCNQ::Proxy::dr_gateway' );
require_ok( 'CCNQ::Proxy::dr_rule' );
require_ok( 'CCNQ::Proxy::endpoint' );
require_ok( 'CCNQ::Proxy::endpoint_number' );
require_ok( 'CCNQ::Proxy::endpoint_location' );
require_ok( 'CCNQ::Proxy::inbound' );
require_ok( 'CCNQ::Proxy::local_number' );
require_ok( 'CCNQ::Proxy::location' );

require_ok( 'CCNQ::Activities' );
require_ok( 'CCNQ::Activities::Billing' );
require_ok( 'CCNQ::Activities::Proxy' );
require_ok( 'CCNQ::Activities::Provisioning' );
require_ok( 'CCNQ::Activities::Number' );

require_ok( 'CCNQ::SQL' );
require_ok( 'CCNQ::SQL::Base' );

require_ok( 'CCNQ::Rating');
require_ok( 'CCNQ::Rating::Bucket');
require_ok( 'CCNQ::Rating::Bucket::DB');
require_ok( 'CCNQ::Rating::Event');
require_ok( 'CCNQ::Rating::Event::Rated');
require_ok( 'CCNQ::Rating::Plan');
require_ok( 'CCNQ::Rating::Process');
require_ok( 'CCNQ::Rating::Rate');
require_ok( 'CCNQ::Rating::Table');

require_ok( 'CCNQ::Actions::b2bua::base' );
require_ok( 'CCNQ::Actions::b2bua::carrier_sbc_config' );
require_ok( 'CCNQ::Actions::b2bua::client_ocs_sbc' );
require_ok( 'CCNQ::Actions::b2bua::client_sbc_config' );
require_ok( 'CCNQ::Actions::b2bua::services' );
require_ok( 'CCNQ::Actions::manager' );
require_ok( 'CCNQ::Actions::mediaproxy' );
require_ok( 'CCNQ::Actions::mediaproxy::dispatcher' );
require_ok( 'CCNQ::Actions::mediaproxy::relay' );
require_ok( 'CCNQ::Actions::monit' );
require_ok( 'CCNQ::Actions::node' );
require_ok( 'CCNQ::Actions::node::api' );
require_ok( 'CCNQ::Actions::node::traces' );
require_ok( 'CCNQ::Actions::db::provisioning' );
require_ok( 'CCNQ::Actions::db::billing' );
require_ok( 'CCNQ::Actions::db::bucket' );
require_ok( 'CCNQ::Actions::db::cdr' );
require_ok( 'CCNQ::Actions::db::invoicing' );
require_ok( 'CCNQ::Actions::proxy::base' );
require_ok( 'CCNQ::Actions::proxy::inbound_proxy' );
require_ok( 'CCNQ::Actions::proxy::outbound_proxy' );
require_ok( 'CCNQ::Actions::proxy::router_no_registrar' );
require_ok( 'CCNQ::Actions::proxy::complete_transparent' );

# These will eventually go.
require_ok( 'CCNQ::Manager::Requests::domain_delete' );
require_ok( 'CCNQ::Manager::Requests::domain_update' );
require_ok( 'CCNQ::Manager::Requests::dr_gateway_delete' );
require_ok( 'CCNQ::Manager::Requests::dr_gateway_update' );
require_ok( 'CCNQ::Manager::Requests::dr_rule_delete' );
require_ok( 'CCNQ::Manager::Requests::dr_rule_update' );
require_ok( 'CCNQ::Manager::Requests::endpoint_delete' );
require_ok( 'CCNQ::Manager::Requests::endpoint_update' );
require_ok( 'CCNQ::Manager::Requests::endpoint_number_delete' );
require_ok( 'CCNQ::Manager::Requests::endpoint_number_update' );
require_ok( 'CCNQ::Manager::Requests::endpoint_location_query' );
require_ok( 'CCNQ::Manager::Requests::raw_endpoint_delete' );
require_ok( 'CCNQ::Manager::Requests::raw_endpoint_update' );
require_ok( 'CCNQ::Manager::Requests::location_update' );
require_ok( 'CCNQ::Manager::Requests::inbound_delete' );
require_ok( 'CCNQ::Manager::Requests::inbound_update' );
require_ok( 'CCNQ::Manager::Requests::local_number_delete' );
require_ok( 'CCNQ::Manager::Requests::local_number_update' );
require_ok( 'CCNQ::Manager::Requests::number_bank_delete' );
require_ok( 'CCNQ::Manager::Requests::number_bank_update' );

require_ok( 'CCNQ::Manager::Requests::node_status_query' );
require_ok( 'CCNQ::Manager::Requests::route_did_update' );
require_ok( 'CCNQ::Manager::Requests::trace_query' );

require_ok( 'CCNQ::Manager::Requests::account_update' );
require_ok( 'CCNQ::Manager::Requests::account_sub_update' );
require_ok( 'CCNQ::Manager::Requests::bucket_update' );
require_ok( 'CCNQ::Manager::Requests::plan_update' );
require_ok( 'CCNQ::Manager::Requests::user_update' );
require_ok( 'CCNQ::Manager::Requests::table_prefix_update' );
require_ok( 'CCNQ::Manager::Requests::table_prefix_bulk_update' );
require_ok( 'CCNQ::Manager::Requests::table_prefix_delete' );
require_ok( 'CCNQ::Manager::Requests::table_update' );

done_testing();
1;

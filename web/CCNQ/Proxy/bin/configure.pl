#!/usr/bin/perl
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

use configuration;
use CCNQ::Proxy::Base;

my $CONFIG = defined $configuration::opensips_cfg ? $configuration::opensips_cfg : '/etc/opensips/opensips.cfg';
my $TEMPLATE = 'CCNQ/Proxy/templates/opensips.cfg';

rename $CONFIG, "$CONFIG.bak";

open(my $fh,'<',$TEMPLATE) or die "open $TEMPLATE: $!";
open(my $fout,'>',$CONFIG) or die "open $CONFIG: $!";

my %avps = %{CCNQ::Proxy::Base::avp()};

# -----------------------
#   CDR_EXTRA
# -----------------------

my @cdr_extra = ();
my @cdr_src = @{CCNQ::Proxy::Base::cdr_extra()};
while(@cdr_src)
{
    my $name = shift @cdr_src;
    my $var  = shift @cdr_src;
    push @cdr_extra, "$name=$var";
}
undef @cdr_src;

# -----------------------
#   RADIUS_EXTRA
# -----------------------

my @radius_extra = ();
my @radius_src = @{CCNQ::Proxy::Base::radius_extra()};
while(@radius_src)
{
    my $name = shift @radius_src;
    my $var  = shift @radius_src;
    push @radius_extra, "$name=$var";
}
undef @radius_src;

my %values = (
    PROXY_IP    => $configuration::sip_host,
    PROXY_PORT  => $configuration::sip_port,
    CHALLENGE   => $configuration::sip_challenge,
    DB_URL      => "mysql://${configuration::db_login}:${configuration::db_password}\@${configuration::db_host}/${configuration::db_name}",
    AVP_ALIASES => join(';',map { "$_=I:$avps{$_}" } (sort keys %avps)),
    CDR_EXTRA   => join(';',@cdr_extra),
    RADIUS_EXTRA   => join(';',@radius_extra),
    NANPA       => 1,
    FR          => 0,
    MPATH       => defined $configuration::mpath ? $configuration::mpath : '/usr/lib/opensips/modules/',
    RADIUS_CONFIG => defined $configuration::radius_config ? $configuration::radius_config : '',
    DEBUG       => defined $configuration::debug ? $configuration::debug : 3,
    MP_ALLOWED  => defined $configuration::mp_allowed ? $configuration::mp_allowed : 1,
    MP_ALWAYS   => defined $configuration::mp_always ? $configuration::mp_always : 0,
    MAX_HOPS    => (defined $configuration::max_hops && $configuration::max_hops ne '') ? $configuration::max_hops : '10',
    # If multiple servers are chained it may be necessary to use different names for the VSF parameter.
    UAC_VSF     => (defined $configuration::uac_vsf && $configuration::uac_vsf ne '') ? $configuration::uac_vsf : 'vsf',
    NODE_ID     => $configuration::node_id || '',
    INV_TIMER   => $configuration::inv_timer || 60,
);

$configuration::accounting = 'flatstore'
    if not defined $configuration::accounting;
$configuration::authenticate = 'db'
    if not defined $configuration::authenticate;

my $accounting_pattern   = '#IF_ACCT_'.uc($configuration::accounting);
my $authenticate_pattern = '#IF_AUTH_'.uc($configuration::authenticate);

while(<$fh>)
{
    s/\$\{([A-Z_]+)\}/defined $values{$1} ? $values{$1} : warn "Undefined $1"/eg;
    s/^${accounting_pattern}//;
    s/^${authenticate_pattern}//;
    s/^#IF_USE_NODE_ID// if $configuration::node_id;
    s/^#USE_PROXY_IP\s*// if $configuration::sip_host;
    print $fout $_;
}

my $sed_dir = ${configuration::install_dir};
$sed_dir =~ s{/}{\\/}g;

my $sed_commands = '';
$sed_commands = <<TXT if ${configuration::install_dir} ne '/var/www';

sed -i bak -e 's/\/var\/www/${sed_dir}/' ${configuration::install_dir}/index.pl
sed -i bak -e 's/\/var\/www/${sed_dir}/' ${configuration::install_dir}/q.pl
sed -i bak -e 's/\/var\/www/${sed_dir}/' ${configuration::install_dir}/CCNQ/Proxy/bin/invite-all.pl
sed -i bak -e 's/\/var\/www/${sed_dir}/' ${configuration::install_dir}/CCNQ/Proxy/bin/invite-outcome.pl
sed -i bak -e 's/\/var\/www/${sed_dir}/' ${configuration::install_dir}/CCNQ/Proxy/bin/invite-single.pl
TXT

print <<TXT;
Please run the following commands:
$sed_commands
mysql <<SQL
    CREATE DATABASE ${configuration::db_name};
    CONNECT ${configuration::db_name};
    CREATE USER ${configuration::db_login} IDENTIFIED BY '${configuration::db_password}';
    GRANT ALL ON ${configuration::db_name}.* TO ${configuration::db_login};
SQL

mysql ${configuration::db_name} < CCNQ/Proxy/templates/opensips.sql

TXT

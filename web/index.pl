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
# $Id$
#
use strict; use warnings;

use lib '/var/www';
use configuration;

use CGI;
my $cgi = new CGI;
$| = 1;

my $_limit = ${configuration::limit} || 100;

my $menu = <<HTML;
<img src="${configuration::theme}logo.png">
<h2>Subscribers</h2>
<ul>
    <li><a href="q.pl?_class=subscriber\&_limit=${_limit}">Subscribers</a></li>
    <li><a href="q.pl?_class=local_number\&_limit=${_limit}">Inbound Numbers</a></li>
    <li>Number <form action="q.pl" method="get"><input type="hidden" name="_class" value="local_number"><input type="text" name="number" value=""><input type="submit" value="Search"></form></li>
</ul>
<h2>Reporting</h2>
<ul>
    <li><a href="q.pl?_class=report_realtime\&_quick=1">Summary report</a></li>
    <li><a href="q.pl?_class=report_calls\&_quick=1">List of call attempts</a></li>
    <li><a href="q.pl?_class=report_call\&_quick=1">Single call by Call-ID</a></li>
    <li><a href="q.pl?_class=report_stats\&_quick=1">Raw statistics</a></li>
</ul>
<h2>Routing</h2>
<ul>
    <li><a href="q.pl?_class=aliases\&_limit=${_limit}">Aliases</a></li>
    <li><a href="q.pl?_class=outbound_route\&_limit=${_limit}">Calling Number based routing</a></li>
    <li>National (NANPA)
        <ul>
            <li><a href="q.pl?_class=national_default\&_limit=${_limit}">Default Routes</a></li>
            <li><a href="q.pl?_class=npa_route\&_limit=${_limit}">NPA Routes</a></li>
            <li><a href="q.pl?_class=npanxx_route\&_limit=${_limit}">NPANXX Routes</a></li>
        </ul>
    <li>International
        <ul>
            <li><a href="q.pl?_class=international_default\&_limit=${_limit}">Default Routes</a></li>
        </ul>
</ul>
<h2>Destination classification</h2>
<ul>
    <li><a href="q.pl?_class=local_npanxx\&_limit=${_limit}">Local NPANXXs</a></li>
    <li><a href="q.pl?_class=premium_npa\&_limit=${_limit}">Premium NPAs</a></li>
    <li><a href="q.pl?_class=premium_nxx\&_limit=${_limit}">Premium NXXs</a></li>
</ul>
<h2>System configuration</h2>
<ul>
    <li><a href="q.pl?_class=domain\&_limit=${_limit}">DNS domains served by this system</a></li>
</ul>
<h2>Trunks</h2>
<ul>
    <li><a href="q.pl?_class=inbound\&_limit=${_limit}">Inbound trunks</a></li>
    <li><a href="q.pl?_class=outbound\&_limit=${_limit}">Outbound trunks</a></li>
</ul>
HTML

print $cgi->header;

if($cgi->param('menu'))
{
    $menu =~ s/<a href=/<a target="content" href=/g;
    $menu =~ s/<form/<form target="content"/g;

    print <<HTML;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
    "http://www.w3.org/TR/html4/strict.dtd">
<html>
    <head>
        <meta http-equiv="Content-type" content="text/html; charset=utf-8">
        <link rel="stylesheet" href="${configuration::theme}default.css" type="text/css" media="screen" title="CarrierClass.net StyleSheet" charset="utf-8" />        <title>Management System</title>
        <title>${configuration::sitename} Management System</title>
    </head>

    <body id="main" onload="">
        $menu
    </body>    
</html>
HTML
}
else
{
    print <<HTML;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN"
   "http://www.w3.org/TR/html4/frameset.dtd">
<html>
    <head>
        <meta http-equiv="Content-type" content="text/html; charset=utf-8">
        <link rel="stylesheet" href="${configuration::theme}default.css" type="text/css" media="screen" title="CarrierClass.net StyleSheet" charset="utf-8" />        <title>Management System</title>
        <title>${configuration::sitename} Management System</title>
    </head>
    <frameset cols="25%, 75%">
        <frame src="?menu=frame" name="menu">
        <frame src="" name="content">
        <noframes>
            $menu
        </noframes>
    </frameset>
</html>
HTML
}

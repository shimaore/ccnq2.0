#!/bin/sh

[ -e /etc/default/sip-traces ] || cp traces/etc/default/sip-traces /etc/default/sip-traces

cp traces/etc/init.d/sip-traces /etc/init.d/sip-traces
chmod +x /etc/init.d/sip-traces

cp traces/usr/sbin/sip-traces /usr/sbin/sip-traces
chmod +x /usr/sbin/sip-traces

update-rc.d sip-traces defaults

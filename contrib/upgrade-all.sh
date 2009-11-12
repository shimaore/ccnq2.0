#!/bin/sh
#(c) 2009 Stephane Alnet
# License: GPL3+

# This is a script I use in order to automatically update the configuration
# on my servers at once.
# It takes one option, '-q', which should be used when only the proxy
# code has changed.

# ~/bin/list.sh should 
#    export SERVERS="server1 server2 ..."
# with all servers.

source ~/bin/list.sh

# I assume you use ssh-agent and sudo NOPASSWD.
# I also assume you installed the source in ~/src/ccnq2.0 as mentioned
# in INSTALL.

if [ "x$1" != "x-q" ]; then
for s in $SERVERS; do
  echo "Server $s"
  ssh $s 'cd /opt/freeswitch && sudo mv conf conf.`date "+%FT%T"`'
done
fi

for s in $SERVERS; do
  echo "Server $s"
  ssh $s 'cd src/ccnq2.0 && git pull' || echo 'Failed'
done

for s in $SERVERS; do
  echo "Server $s"
  ssh $s 'cd src/ccnq2.0/common/bin && sudo ./upgrade.pl && sudo tail -100 /var/log/syslog | grep -i error'
done

if [ "x$1" != "x-q" ]; then
for s in $SERVERS; do
  echo "Server $s"
  ssh $s 'cd /etc && sudo git add . && sudo git commit -a -m "Update"'
done

exec ~/bin/xmpp-restart-all.sh
fi

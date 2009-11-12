#!/bin/sh
#(c) 2009 Stephane Alnet
# License: GPL3+

# This is a script I use in order to automatically restart the XMPP Agent
# on all servers.

# ~/bin/list.sh should 
#    export SERVERS="server1 server2 ..."
# with all servers.

source ~/bin/list.sh

# I assume you use ssh-agent and sudo NOPASSWD.
# I also assume you installed the source in ~/src/ccnq2.0 as mentioned
# in INSTALL.

for s in $SERVERS; do
  echo "Server $s"
  ssh $s 'cd src/ccnq2.0/common/bin || exit; killall xmpp_agent.pl; rm -f nohup.out; (nohup ./xmpp_agent.pl </dev/null >/dev/null 2>/dev/null &)' || echo 'Failed'
done

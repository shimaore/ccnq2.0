#!/bin/bash
# Usage:
#   run-all.sh <script> [<script> ...]

export LANG=C

if [ "x$SERVERS" == "x" ]; then source /etc/ccn/servers; fi

if true; then
  for s in $SERVERS; do
    echo "-----------------------= Server $s =-----------------------"

    for SCRIPT in $*; do
      scp $SCP_OPTIONS $SCRIPT $s:
      # (ssh $SSH_OPTIONS $s "chmod +x $SCRIPT && dpkg-architecture -c $SCRIPT")&
      ssh $SSH_OPTIONS $s "chmod +x $SCRIPT && dpkg-architecture -c ./$SCRIPT"
    done

  done
fi

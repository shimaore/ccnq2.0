#!/bin/sh

# This script must be installed on the server that runs the
# FreeSwitch instance we want to update, alongside dialplan.pl

FS=/opt/freeswitch
XML_OUTPUT=${FS}/conf/dialplan/routing/cdb.xml

./dialplan.pl $1 > ${XML_OUTPUT}.new && \
  chown freeswitch.daemon ${XML_OUTPUT}.new && \
  mv ${XML_OUTPUT}.new ${XML_OUTPUT} && \
  ${FS}/bin/fs_cli -x 'reloadxml'

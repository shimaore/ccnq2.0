#!/bin/sh

# SRC: where the copy of the original code lies.
# I create mine in ~/src using:
#    cd $HOME/src && git clone git://github.com/stephanealnet/ccnq2.0.git
export SRC=$HOME/src/ccnq2.0/proxies

# WWW: Where the web content actually lies.
export WWW=/var/www

# MODEL: Which model is used for the local opensips system
# Must be onre of the *.recipe names:
#    complete-transparent
#    complete
#    inbound-proxy
#    outbound-proxy
#    registrar
#    router-no-registrar
#    router
export MODEL=complete-transparent

# end of configuration parameters.

# Update the code in the local repository
echo "Updating the code in the local repository"
(cd $SRC && git pull)
# Copy the updated web code to its actual destination
echo "Copying the updated web code to its actual destination"
cp -a $SRC/web/* $WWW/
cp -a $SRC/CCNQ  $WWW/
# Generate a new opensips.cfg and opensips.sql file and push them
echo "Generating a new opensips.cfg and opensips.sql"
(cd $SRC/opensips && mkdir -p output && ./build.sh $MODEL && mkdir -p $WWW/CCNQ/Proxy/templates && mv output/opensips.* $WWW/CCNQ/Proxy/templates)
# Reconfigure the local system (includes installing the new opensips.cfg file in /etc/opensips)
echo "Reconfiguring the local system"
(cd $WWW && sudo perl CCNQ/Proxy/bin/configure.pl)
# Restart OpenSIPS using the new configuration.
echo "Restarting OpenSIPS"
sudo /etc/init.d/opensips restart

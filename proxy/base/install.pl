
my ($hostname,$domain_name,$cluster_name,$role,$function) = @ARGV;

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

# Generate a new opensips.cfg and opensips.sql file and push them
echo "Generating a new opensips.cfg and opensips.sql"
(cd $SRC/base/opensips && mkdir -p output && ./build.sh $MODEL && mv output/opensips.* $WWW/CCNQ/Proxy/templates)
# Reconfigure the local system (includes installing the new opensips.cfg file in /etc/opensips)
echo "Reconfiguring the local system"
(cd $WWW && sudo perl CCNQ/Proxy/bin/configure.pl)
# Restart OpenSIPS using the new configuration.
echo "Restarting OpenSIPS"
sudo /etc/init.d/opensips restart

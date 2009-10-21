{
  # Used to provide server-wide status information.
  status => sub {
    return {
      running => 1,
    };
  },
  
  restart_all => sub {
    die CCNQ::Install::xmpp_restart_all; # as used in xmpp_agent.pl
  },
}
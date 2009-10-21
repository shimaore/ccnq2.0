{
  install_all => sub {
    CCNQ::Install::attempt_on_roles_and_functions('install');
    return;
  },

  upgrade => sub {
    # Update the code from the Git repository.
    chdir(CCNQ::Install::SRC) or die "chdir(".CCNQ::Install::SRC."): $!";
    CCNQ::Install::_execute(qw( git pull ));
    # Switch back to the directory we normally run from.
    chdir(CCNQ::Install::install_script_dir) or die "chdir(".CCNQ::Install::install_script_dir."): $!";
    return;
  },

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
# These instructions were originally in INSTALL.

# XXX Replace these with how to use dh-make-perl : dh-make-perl --build --cpan <package-name> && dpkg-buildpackage
cpan File::ShareDir # Obsolete version in Debian Lenny or testing
sudo cpan EV
sudo cpan AnyEvent::XMPP
sudo cpan AnyEvent::Watchdog
sudo cpan constant::defer
sudo cpan Test::More
# The proxies need AnyEvent::DBI
sudo cpan AnyEvent::DBI
# The (manager) client also needs AnyEvent::CouchDB
sudo cpan AnyEvent::HTTP CouchDB::View AnyEvent::CouchDB
# Generally speaking you might want to install/upgrade those for better performance with AnyEvent
sudo cpan Async::Interrupt EV Guard JSON JSON::XS Net::SSLeay

# ------ Equivalent (on your build server): ------------
alias dh='dh-make-perl --build --cpan '

dh common-sense
sudo dpkg -i libcommon-sense-perl_*.deb
dh EV

dh Params::Util
sudo dpkg -i libparams-util-perl_*.deb
dh Class::Inspector
sudo dpkg -i libclass-inspector-perl_*.deb
dh File::ShareDir

dh XML::Parser::Expat
sudo dpkg -i libxml-parser-perl_*.deb
dh AnyEvent
sudo dpkg -i libanyevent-perl_*.deb
dh Digest::SHA1
sudo dpkg -i libdigest-sha1-perl_*.deb
dh Object::Event
sudo dpkg -i libobject-event-perl_*.deb
dh Authen::SASL
sudo dpkg -i libauthen-sasl-perl_*.deb
dh Net::LibIDN
# (fails)
(cd Net-LibIDN-* && dpkg-buildpackage)
sudo dpkg -i libnet-libidn-perl_*.deb
dh XML::Writer
sudo dpkg -i libxml-writer-perl_*.deb
dh AnyEvent::XMPP

dh AnyEvent::WatchDog
dh constant::defer

# Note: this is not good. I should write better test plans.
dh-make-perl --build --core-ok --cpan Test::More

dh AnyEvent::DBI

dh AnyEvent::HTTP
sudo dpkg -i libanyevent-http-perl_*.deb

dh PadWalker
sudo dpkg -i libpadwalker-perl_*.deb
dh CouchDB::View
sudo dpkg -i libcouchdb-view-perl_*.deb
dh IO::String
sudo dpkg -i libio-string-perl_*.deb
dh IO::All
sudo dpkg -i libio-all-perl_*.deb
dh AnyEvent::CouchDB
dh Async::Interrupt
dh Guard

# For the portal
dh String::CRC32
sudo dpkg -i libstring-crc32-perl_*.deb
dh Cache::Memcached

# We provide pre-built archives for AMD64 architecture, see INSTALL.

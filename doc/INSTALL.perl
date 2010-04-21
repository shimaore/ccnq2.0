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
alias dp='dh-make-perl --build --cpan '

dp common-sense
sudo dpkg -i libcommon-sense-perl_*.deb
dp EV

dp Params::Util
sudo dpkg -i libparams-util-perl_*.deb
dp Class::Inspector
sudo dpkg -i libclass-inspector-perl_*.deb
dp File::ShareDir
sudo dpkg -i libfile-sharedir-perl_*.deb # Needed to compile Plack later

dp XML::Parser::Expat
sudo dpkg -i libxml-parser-perl_*.deb
dp AnyEvent
sudo dpkg -i libanyevent-perl_*.deb
dp Digest::SHA1
sudo dpkg -i libdigest-sha1-perl_*.deb
dp Object::Event
sudo dpkg -i libobject-event-perl_*.deb
dp Authen::SASL
sudo dpkg -i libauthen-sasl-perl_*.deb
dp Net::LibIDN
# (fails)
(cd Net-LibIDN-* && dpkg-buildpackage)
sudo dpkg -i libnet-libidn-perl_*.deb
dp XML::Writer
sudo dpkg -i libxml-writer-perl_*.deb
dp AnyEvent::XMPP

dp AnyEvent::WatchDog
dp constant::defer

# Note: this is not good. I should write better test plans.
dp-make-perl --build --core-ok --cpan Test::More

dp AnyEvent::DBI

dp AnyEvent::HTTP
sudo dpkg -i libanyevent-http-perl_*.deb

dp PadWalker
sudo dpkg -i libpadwalker-perl_*.deb
dp CouchDB::View
sudo dpkg -i libcouchdb-view-perl_*.deb
dp IO::String
sudo dpkg -i libio-string-perl_*.deb
dp IO::All
sudo dpkg -i libio-all-perl_*.deb
dp AnyEvent::CouchDB
dp Async::Interrupt
dp Guard

# For the portal
dp String::CRC32
sudo dpkg -i libstring-crc32-perl_*.deb
dp Cache::Memcached

dp HTTP::Server::Simple
sudo dpkg -i libhttp-server-simple-perl_*.deb
dp HTTP::Server::Simple::PSGI
sudo dpkg -i libhttp-server-simple-psgi-perl_*.deb
dp URI
sudo dpkg -i liburi-perl_*.deb
dp HTTP::Body
sudo dpkg -i libhttp-body-perl_*.deb
dp MIME::Types
sudo dpkg -i libmime-types-perl_*.deb

# Use Dancer from git
git clone git://github.com/sukria/Dancer.git && (cd Dancer && dh-make-perl --build)
# Use Dancer::Session::Memcached from git
git clone git://github.com/sukria/Dancer-Session-Memcached.git && (cd Dancer-Session-Memcached && dh-make-perl --build)

dp Locale::Maketext::Lexicon
dp CGI::Untaint
sudo dpkg -i libcgi-untaint-perl_*.deb
dp Digest::HMAC_MD5
sudo dpkg -i libdigest-hmac-perl_*.deb
dp Net::IP
sudo dpkg -i libnet-ip-perl*.deb
dp Net::DNS
sudo dpkg -i libnet-dns-perl_*.deb
dp Email::Valid
sudo dpkg -i libemail-valid-perl_*.deb
dp Mail::Address
sudo dpkg -i libmailtools-perl_*.deb
dp CGI::Untaint::email
dp Crypt::CBC
dp Crypt::Rijndael
dp Lingua::EN::Numbers::Ordinate
dp Lingua::FR::Numbers
# dp Lingua::FR::Numbers::Ordinate

dp AnyEvent::HTTPD

# We provide pre-built archives for AMD64 architecture, see INSTALL.

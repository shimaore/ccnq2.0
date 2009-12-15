package CCNQ::API::handler;
# Copyright (C) 2009  Stephane Alnet
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 3
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
use strict; use warnings;

use CCNQ::API;

# See also Path::Dispatcher::Declarative  ?

# XXX Rewrite node/api/actions.pm et al. to use JSON-RPC naming (i.e. "method" instead of "action", "result" instead of "params" for responses)

sub make_couchdb_proxy {
  my ($context,$view_name,$key_prefix,$key_fields,$readable_fields,$writable_fields) = @_;
  my $couch_db = couchdb(CCNQ::API::provisioning_db);
  my $nb_fields = $#{$key_fields}+1;

  return sub {
    my ($httpd, $req) = @_;

    debug("make_couchdb_proxy: Processing web request");

    use URI;
    my $url = URI->new($req->url);
    my $path = $url->path;
    my @path = split(m{/},$path);

    my @key_values = @path[1..$nb_fields];

    my $field = $path[$nb_fields+1];

    my $cv = $couch_db->view($view_name, { key => encode_json([$key_prefix,@key_values]) });
    $cv->cb(sub{
      my $doc = $_[0]->recv;

      if($req->method eq 'GET') {

        if( defined($field) ) {

          if(!grep { $_ eq $field } @{$readable_fields}) {
            $req->respond([501,'Invalid method']);
            $httpd->stop_request;
            return;
          }

          if(exists($doc->{$field})) {
            my $json_content = encode_json($doc->{$field});
            debug("node/account: Return value: $json_content");
            $req->respond([200,'OK',{ 'Content-Type' => 'text/json' },$json_content]);
          } else {
            debug("node/account: Return value: undef");
            $req->respond([204,'No content']);
          }

        } else {

          my $json_content = encode_json($doc);
          debug("node/account: Return value: $json_content");
          $req->respond([200,'OK',{ 'Content-Type' => 'text/json' },$json_content]);

        }

      } elsif($req->method eq 'PUT') {

        if( defined($field) ) {

          if(!grep { $_ eq $field } @{$writable_fields}) {
            $httpd->stop_request;
            return;
          }

          $doc->{$field} = $req->vars->{value};

        } else {

          foreach my $field ($writable_fields) {
            $doc->{$_} = $req->vars->{$field};
          }

        }

        $db->save_doc($request)->cb(sub{ $_[0]->recv;
          $req->respond([200,'OK']);
        });

      } else {
        $req->respond([501,'Invalid method']);
        $httpd->stop_request;
        return;
      }
    });
    $context->{condvar}->cb($cv);
  };
}

1;

local helpers = require 'couchdb.helpers'
local json = require 'json'

module(...)

-- http://wiki.apache.org/couchdb/HTTP_Document_API

-- You can have / as part of the DocID but if you refer to a document in a URL 
-- you must always encode it as %2F. One special case is _design/ documents, 
-- those accept either / or %2F for the / after _design, although / is preferred 
-- and %2F is still needed for the rest of the DocID. 

-- valid params = startkey, endkey, limit, descending=true, and include_docs=true
function all(server, database, params)
	return helpers.run_request(helpers.url(server, database, "_all_docs", params), "GET")
end

function get(server, database, document_id, rev)
	return helpers.run_request(helpers.url(server, database, document_id, { rev = rev }), "GET")
end

function delete(server, database, document_id, rev)
	return helpers.run_request(helpers.url(server, database, document_id, { rev = rev }), "DELETE")
end

function create(server, database, document, document_id)
	if document_id then
		return helpers.run_request(helpers.url(server, database, document_id), "PUT", json.encode(document))
	else
		return helpers.run_request(helpers.url(server, database), "POST", json.encode(document))
	end
end

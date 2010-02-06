local helpers = require 'couchdb.helpers'

module(...)

-- http://wiki.apache.org/couchdb/HTTP_database_API

-- A database must be named with all lowercase characters (a-z), digits (0-9), 
-- or any of the _$()+-/ characters and must end with a slash in the URL. 
-- The name has to start with characters. 

-- Note also that a / character in a DB name must be escaped when used in a URL; 
-- if your DB is named his/her then it will be available at 
-- [WWW] http://localhost:5984/his%2Fher. 

function all(server)
	return helpers.run_request(helpers.url(server, nil, "_all_dbs"), "GET")
end

function create(server, database)
	return helpers.run_request(helpers.url(server, database), "PUT")
end

function delete(server, database)
	return helpers.run_request(helpers.url(server, database), "DELETE")
end

function info(server, database)
	return helpers.run_request(helpers.url(server, database), "GET")
end

function compact(server, database)
	return helpers.run_request(helpers.url(server, database, "_compact"), "POST")
end
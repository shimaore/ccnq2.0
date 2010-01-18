local json = require "json"
local http = require "socket.http"
local ltn12 = require "ltn12"
local table = require "table"
local string = require "string"

local pairs = pairs

module(...)

local function http_request(url, method, body)
	method = method or "GET"
	
	local source = nil
	local headers = nil
	
	if body then
		source = ltn12.source.string(body)
		headers = { ["content-length"] = body:len() }
	end
	
	local result = {}
	local _, response_code, headers = http.request {
	  method = method,
	  url = url,
		sink = ltn12.sink.table(result),
		source = source,
		headers = headers
	}

	return table.concat(result), response_code, headers
end

function run_request(url, method, body)
	local response_body, response_code, headers = http_request(url, method, body)
	return json.decode(response_body), response_code, headers
end

function stringify_params(params)
	local params_string = ""

	if params then
		params_sep = "?"
		for name, value in pairs(params) do
			params_string = string.format("%s%s%s=%s", params_string, params_sep, name, value)
			params_sep = "&"
		end
	end
	
	return params_string
end

function url(server, db, path, params)
	local params_string = stringify_params(params)
	
	if db and path then
		return string.format("http://%s/%s/%s%s", server, db, path, params_string)
	elseif db then
		return string.format("http://%s/%s/%s", server, db, params_string)
	elseif path then
		return string.format("http://%s/%s%s", server, path, params_string)
	else
		return string.format("http://%s/%s", server, params_string)
	end
end

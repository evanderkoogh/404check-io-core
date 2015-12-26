cheerio = require 'cheerio'
url_parse = require 'url'
zlib = require 'zlib'
request = require 'request'
async = require 'async'
cache = require './cache.js'

headers =
	'user-agent': '404check.io (http://404check.io)'
agentOptions =
	keepAlive: true
	maxSockets: 4
request = request.defaults {headers, agentOptions, timeout: 5000}

exports.check_url = (url, cb) ->
	request.get {uri: url, gzip:true}, (err, res, body) ->
		statusCode = if res then res.statusCode else "ERR: #{err}"
		cache.set url, statusCode
		results =
			url: url
			statusCode: statusCode
			links: {}

		return cb(null, results) if statusCode isnt 200

		links = extract_links body, url
		
		check = (link, cb) ->
			check_link link, (err, statusCode) ->
				if err
					results.links[link] = err
				else
					results.links[link] = statusCode
				cb()
		
		async.each links, check, (err) ->
			cb(null, results)

check_link = (link, cb) ->
	cache.get link, (err, statusCode) ->
		if statusCode
			cb(err, statusCode)
		else
			request.head link, (err, res) ->
				if res?.statusCode is 405
					request.get link, (err, res) ->
						statusCode = if res then res.statusCode else "ERR: #{err}"
						cache.set link, statusCode
						cb(err, statusCode)
				else								
					statusCode = if res then res.statusCode else "ERR: #{err}"
					cache.set link, statusCode
					cb(err, statusCode)

extract_links = (html, url) ->
	$ = cheerio.load html
	links = {}
	$('a').each () ->
		a = $(this)
		link = a.attr 'href'
		if link
			abs_link = url_parse.resolve url, link
			if abs_link.indexOf('http') is 0
				links[abs_link] = abs_link.split('?')[0].split('#')[0]
	return (val for key, val of links)
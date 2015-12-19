{EventEmitter} = require 'events'

cache = {}
emitter = new EventEmitter
emitter.setMaxListeners(50)

exports.get = (url, cb) ->
	if cache[url] is "In Progress"
		emitter.once url, cb
	else if cache[url]
		cb null, cache[url]
	else
		cache[url] = "In Progress"
		cb null, null
		

exports.set = (url, statusCode) ->
	cache[url] = statusCode
	emitter.emit url, null, statusCode
	emitter.removeAllListeners url
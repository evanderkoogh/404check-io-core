async = require 'async'
done = require './done.js'

processRecord = (record, cb) ->
	if record.eventName is 'MODIFY'
		done.checkDone record, cb
	else
		async.setImmediate cb

exports.handler = (event, context) ->
	async.each event.Records, processRecord, (err) ->
		context.done(err)
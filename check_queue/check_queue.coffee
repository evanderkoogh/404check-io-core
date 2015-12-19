AWS = require 'aws-sdk'
async = require 'async'
check = require './check.js'
save = require './save_results.js'

sqs = new AWS.SQS()

processMessage = (msg, cb) ->
	body = JSON.parse msg.Body
	console.log "URL: #{body.url}  -  Id: #{body.report_id}"
	url = body.url
	console.log "Checking URL: #{url}"
	check.check_url url, (err, results) ->
		results.report_id = body.report_id
		save.saveResults results, (err) ->
			if err
				return cb err
			deleteMessage msg.ReceiptHandle, (err) ->
				cb err

deleteMessage = (receiptHandle, cb) ->
	params =
		QueueUrl: 'https://sqs.eu-west-1.amazonaws.com/812926173749/404_urls_to_check'
		ReceiptHandle: receiptHandle
	sqs.deleteMessage params, (err, data) ->
		cb()

getMessages = (callback) ->
	params =
		QueueUrl: 'https://sqs.eu-west-1.amazonaws.com/812926173749/404_urls_to_check'
		MaxNumberOfMessages: 10
		WaitTimeSeconds: 3
	sqs.receiveMessage params, (err, data) ->
		console.log "Found #{data.Messages?.length} messages"
		callback err, data.Messages

exports.handler = (event, context) ->
	console.log JSON.stringify(event, null, 2)
	queue = async.queue processMessage, 10

	fillQueue = (callback) ->
		console.log "Filling queue"
		getMessages (err, messages) ->
			queue.push messages if messages
			callback()

	async.doUntil fillQueue, queue.idle, (err) ->
		context.done err
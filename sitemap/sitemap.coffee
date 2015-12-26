AWS = require 'aws-sdk'
sitemap_parser = require 'sitemap-stream-parser'
async = require 'async'

sqs = new AWS.SQS()
dbDoc = new AWS.DynamoDB.DocumentClient()
lambda = new AWS.Lambda()

sendURLsToSQS = (urls, reportId, cb) ->
	params =
		Entries: ({Id: "#{index}", MessageBody: JSON.stringify({url, report_id: reportId}) } for url, index in urls)
		QueueUrl: 'https://sqs.eu-west-1.amazonaws.com/812926173749/404_urls_to_check'
	console.log params
	sqs.sendMessageBatch params, (err, data) ->
		console.log err if err
		cb err

saveReport = (total_urls, reportId, cb) ->
	params =
		Key:
			id: reportId
		TableName: '404_Reports'
		AttributeUpdates:
			status:
				Action: 'PUT'
				Value: 'IN_PROGRESS'
			total_urls:
				Action: 'PUT'
				Value: total_urls

	console.log params
	dbDoc.update params, (err, data) ->
		console.log err if err
		console.log data if data
		cb err

wakeUpQueue = (cb) ->
	lambda.invoke {FunctionName: '404_Check_URL_Queue', InvocationType: 'Event'}, (err, data) ->
		console.error err if err
		console.log data if data
		cb()

wrapUp = (urls, total_urls, reportId, cb) ->
	tasks =
		sendURLs: (done) ->
			sendURLsToSQS urls, reportId, done
		wakeUpQueue: (done) ->
			wakeUpQueue done
		saveReport: (done) ->
			saveReport total_urls, reportId, done
	async.parallel tasks, cb

exports.handler = (event, context) ->
	console.log JSON.stringify(event, null, 2)

	sitemap_parse_done = false
	reportId = event.reportId
	total_urls = 0
	urls = []

	sendURLs = (urls, cb) ->
		sendURLsToSQS urls.array, reportId, cb

	queue = async.queue sendURLs, 10
	queue.drain = () ->
		if sitemap_parse_done
			wrapUp urls, total_urls, reportId, (err) ->
				context.done err
	
	url_cb = (url) ->
		total_urls++
		urls.push url
		if urls.length is 10
			queue.push {array: urls}
			urls = []

	sitemap_parser.parseSitemaps event.sitemaps, url_cb, (err) ->
		unless err
			sitemap_parse_done = true
			if queue.idle() 
			 	wrapUp urls, total_urls, reportId, (err) ->
			 		context.done err
		else
			context.fail err
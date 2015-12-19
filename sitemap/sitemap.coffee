AWS = require 'aws-sdk'
sitemap_urls = require 'sitemap-urls'
request = require 'request'
async = require 'async'

db = new AWS.DynamoDB()
dbDoc = new AWS.DynamoDB.DocumentClient()
sqs = new AWS.SQS()
lambda = new AWS.Lambda()

queueUrls = (urls, report_id, cb) ->
	queueUrl = (url, cb) ->
		params =
			MessageBody: JSON.stringify({url, report_id})
			QueueUrl: 'https://sqs.eu-west-1.amazonaws.com/812926173749/404_urls_to_check'
		sqs.sendMessage params, (err, data) ->
			console.log err if err
			cb err

	console.log "Saving #{urls.length} URLs"
	async.eachLimit urls, 25, queueUrl, (err) ->
		console.log err if err
		cb err, urls.length

generateId = (event) ->
	return Date.now().toString()

saveReport = (report, cb) ->
	params =
		Item: report
		TableName: '404_Reports'
	console.log params
	dbDoc.put params, (err, data) ->
		cb err

invokeQueue = (cb) ->
	params =
		FunctionName: '404_Check_URL_Queue'
		InvocationType: 'Event'
	lambda.invoke params, (err, data) ->
		console.log err if err
		console.log data if data
		cb()

extractUrls = (sitemap, cb) ->
	console.log "Retrieving URL: #{sitemap}"
	request.get sitemap, (err, res, body) ->
		if err
			console.log "Can not retrieve URL: #{err}"
			return cb err
		urls = sitemap_urls.extractUrls body
		if urls
			cb null, urls
		else
			console.log "#{url} is not a valid sitemap"
			cb "#{url} is not a valid sitemap"

exports.handler = (event, context) ->
	console.log JSON.stringify(event, null, 2)
	report =
		id: generateId()
		sitemap: event.sitemap
		status: 'STARTED'
		email: 'erwin@koogh.com'
		submitted: new Date().toString()
		errors: {}
	extractUrls report.sitemap, (err, urls) ->
		return context.done err if err
		queueUrls urls, report.id, (err, count) ->
			report.total_urls = count
			report.status = 'IN_PROGRESS'
			saveReport report, (err) ->
				invokeQueue () ->
					context.done err, report
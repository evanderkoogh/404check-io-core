AWS = require 'aws-sdk'
sitemap_parser = require 'sitemap-stream-parser'

sqs = new AWS.SQS()
dbDoc = new AWS.DynamoDB.DocumentClient()
lambda = new AWS.Lambda()

queueUrls = (urls, reportId) ->
	params =
		Entries: ({Id: "#{index}", MessageBody: JSON.stringify({url, report_id: reportId}) } for url, index in urls)
		QueueUrl: 'https://sqs.eu-west-1.amazonaws.com/812926173749/404_urls_to_check'
	console.log params
	sqs.sendMessageBatch params, (err, data) ->
		console.log err if err

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
	lambda.invoke {FunctionName: '404_Check_URL_Queue', InvocationType: 'Event' }, cb

exports.handler = (event, context) ->
	console.log JSON.stringify(event, null, 2)
	reportId = event.reportId

	total_urls = 0
	urls = []
	url_cb = (url) ->
		total_urls++
		urls.push url
		if urls.length is 10
			queueUrls urls, reportId
			urls = []

	sitemap_parser.parseSitemaps event.sitemaps, url_cb, (err) ->
		queueUrls urls, reportId if urls.length > 0
		unless err
			wakeUpQueue () ->
			saveReport total_urls, reportId, (err) ->
				context.done err
		else
			context.fail err
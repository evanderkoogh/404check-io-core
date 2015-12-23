AWS = require 'aws-sdk'
request = require 'request'
sitemap_parser = require 'sitemap-stream-parser'

dbDoc = new AWS.DynamoDB.DocumentClient()
lambda = new AWS.Lambda()

findSitemaps = (hostname, cb) ->
	sitemap_parser.sitemapsInRobots "http://#{hostname}/robots.txt", (err, sitemaps) ->
		if sitemaps instanceof Array and sitemaps.length > 0
			return cb null, sitemaps
		else
			url = "http://#{hostname}/sitemap.xml"
			request.head url, (err, res) ->
				if res.statusCode is 200
					return cb null, [url]
				else
					cb "Could not find one or more sitemaps for hostname: #{hostname}"

processSitemaps = (sitemaps, done) ->
	params =
		FunctionName: '404_New_Sitemap'
		InvocationType: 'Event'
		Payload: JSON.stringify({sitemap: sitemaps[0]})
	done()
	lambda.invoke params, (err, data) ->
		console.log err if err
		console.log data if data
		done err

saveReport = (hostname, sitemaps, cb) ->
	isoDate = new Date().toISOString().substring(0, 10)
	report =
		id: "#{hostname}_#{isoDate}"
		hostname: hostname
		date: isoDate
		sitemaps: sitemaps
		status: 'SUBMITTED'
		submitted: new Date().toString()
	
	params =
		Item: report
		TableName: '404_Reports'
	console.log 'Parameters going into saveReport:'
	console.log params
	dbDoc.put params, (err, data) ->
		console.log 'Data coming back from saveReport:'
		console.log data
		cb err, report

exports.handler = (event, context) ->
	console.log JSON.stringify(event, null, 2)
	findSitemaps event.hostname, (err, sitemaps) ->
		unless err
			processSitemaps sitemaps, (err) ->
				unless err
					saveReport event.hostname, sitemaps, (err, report) ->
						context.done err, report
				else
					context.fail err
		else
			context.fail err
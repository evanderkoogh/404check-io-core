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

processSitemaps = (sitemaps, reportId, done) ->
	params =
		FunctionName: '404_New_Sitemap'
		InvocationType: 'Event'
		Payload: JSON.stringify({ sitemaps, reportId })
	done()
	lambda.invoke params, (err, data) ->
		console.log err if err
		console.log data if data
		done err

saveReport = (id, hostname, sitemaps, cb) ->
	report =
		id: id
		hostname: hostname
		date: new Date().toISOString().substring(0, 10)
		sitemaps: sitemaps
		status: 'SUBMITTED'
		submitted: new Date().toString()
		errors: {}
	
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
	hostname = event.hostname
	findSitemaps hostname, (err, sitemaps) ->
		unless err
			reportId = "#{hostname}_#{new Date().toISOString().substring(0, 10)}"
			processSitemaps sitemaps, reportId, (err) ->
				unless err
					saveReport reportId, hostname, sitemaps, (err, report) ->
						context.done err, report
				else
					context.fail err
		else
			context.fail err
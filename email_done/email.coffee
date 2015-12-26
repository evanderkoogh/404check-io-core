AWS = require 'aws-sdk'
async = require 'async'

ses = new AWS.SES()
dbDoc = new AWS.DynamoDB.DocumentClient()

parseRecord = (record, cb) ->
	return JSON.parse(record.Sns.Message).id

getReport = (id, cb) ->
	params =
		Key:
			id: id
		TableName: '404_Reports'
	dbDoc.get params, (err, data) ->
		cb err, data.Item

sendEmail = (report, cb) ->
	console.log "Sending an email for report: #{report.id} to #{report.email}?"
	if report.email
		params =
			Source: 'admin@404check.io'
			Destination:
				ToAddresses: [report.email]
			Message:
				Subject:
					Data: 'Your 404check.io report is done.'
				Body:
					Text:
						Data: "Hello, \nYour report with id: #{report.id} is done. You can view it here: http://404check.io/reports.html?#{report.id}\nThanks, \nTeam 404check.io" 
		ses.sendEmail params, (err, data) ->
			console.log err if err
			console.log data if data
			cb err
	else
		async.setImmediate cb

exports.handler = (event, context) ->
	ids = (parseRecord(record) for record in event.Records)
	async.map ids, getReport, (err, reports) ->
		unless err 
			async.each reports, sendEmail, (err) ->
				context.done err
		else
			console.error err
			context.fail err
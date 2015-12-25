AWS = require 'aws-sdk'
async = require 'async'

ses = new AWS.SES()

parseRecord = (record, cb) ->
	console.log JSON.stringify(record, null, 2)
	console.log JSON.stringify(record.Sns.Message, null, 2)
	return JSON.parse(record.Sns.Message).report_id

getReport = (id, cb) ->
	params =
		Key:
			id: id
		TableName: '404_Reports'
	dbDoc.get params, cb

sendEmail = (report, cb) ->
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
	async.setImmediate cb

exports.handler = (event, context) ->
	ids = (parseRecord(record) for record in event.Records)
	async.map ids, getReport, (err, reports) ->
		async.each reports, sendEmail, (err) ->
			context.done err
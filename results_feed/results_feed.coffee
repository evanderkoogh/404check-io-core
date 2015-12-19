AWS = require 'aws-sdk'
async = require 'async'

db = new AWS.DynamoDB()
dbDoc = new AWS.DynamoDB.DocumentClient()

parseRecord = (record) ->
	info =
		report_id: record.dynamodb.Keys.report_id.S
		url: record.dynamodb.Keys.url.S
		errors: {}

	map = record.dynamodb.NewImage.results.M
	for url, value of map
		if value.S isnt '200'
			info.errors[url] = value.S
	return info

processRecord = (reports, record) ->
	report = reports[record.report_id]
	unless report
		report = {}
		report.id = record.report_id
		report.count = 0
		report.errors = {}
	report.count++
	if record.errors and record.errors isnt {}
		report.errors[record.url] = record.errors 
	reports[record.report_id] = report

saveReport = (report, id, cb) ->
	params =
		Key:
			id: id
		TableName: '404_Reports'
		ExpressionAttributeValues:
			":count": report.count
		UpdateExpression: "add done_urls :count set"
	i = 0
	for url, errors of report.errors
		index = "url#{i++}"
		params.ExpressionAttributeNames = {} unless params.ExpressionAttributeNames
		params.ExpressionAttributeNames["##{index}"] = "#{url}"
		params.ExpressionAttributeValues[":#{index}"] = errors
		params.UpdateExpression = params.UpdateExpression + " errors.##{index} = :#{index},"

	params.UpdateExpression = params.UpdateExpression.substring(0, params.UpdateExpression.length - 1)

	console.log JSON.stringify(params, null, 2)

	dbDoc.update params, (err, data) ->
		console.log err if err
		console.log data if data
		cb(err)

exports.handler = (event, context) ->
	inserts = (record for record in event.Records when record.eventName is 'INSERT' )
	records = (parseRecord(record) for record in inserts)
	reports = {}
	processRecord reports, record for record in records
	
	async.forEachOf reports, saveReport, (err) ->
		context.done err
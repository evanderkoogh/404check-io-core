AWS = require 'aws-sdk'

dbDoc = new AWS.DynamoDB.DocumentClient()

exports.checkDone = (record, cb) ->
	report = record.dynamodb.NewImage
	done_urls = report.done_urls?.N
	status = report.status?.S
	console.log "#{done_urls} URLs done.."
	if done_urls and done_urls is report.total_urls?.N and status is 'IN_PROGRESS'
		console.log "WE ARE DONE!"
		saveDone record.dynamodb.Keys.id.S, cb
	else
		process.nextTick cb

saveDone = (id, cb) ->
	params =
		Key:
			id: id
		TableName: '404_Reports'
		ExpressionAttributeNames:
			"#status": 'status'
		ExpressionAttributeValues:
			":done": 'DONE'
			":now": new Date().toString()
		UpdateExpression: "SET #status = :done, finished = :now"

	console.log 'Closing the report'
	console.log params

	dbDoc.update params, (err, data) ->
		console.log err if err
		console.log data if data
		cb(err)
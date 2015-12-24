AWS = require 'aws-sdk'
async = require 'async'

dbDoc = new AWS.DynamoDB.DocumentClient()
sns = new AWS.SNS();

exports.checkDone = (record, cb) ->
	report = record.dynamodb.NewImage
	done_urls = report.done_urls?.N
	status = report.status?.S
	console.log "#{done_urls} URLs done.."
	if done_urls and done_urls is report.total_urls?.N and status is 'IN_PROGRESS'
		done record.dynamodb.Keys.id.S, cb
	else
		process.nextTick cb

done = (id, cb) ->
	console.log "WE ARE DONE!"
	tasks =
		save: (done) ->
			saveDone id, done		
		notify: (done) ->
			notifyDone id, done
	async.parallel tasks, (err) ->
		cb err

notifyDone = (id, cb) ->
	params =
		Message: JSON.stringify({ id })
		TopicArn: 'arn:aws:sns:eu-west-1:812926173749:404_Report_Done'
	sns.publish params, (err, data) ->
		console.log err if err
		console.log data if data
		cb err, data

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
		cb err, data
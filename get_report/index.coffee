AWS = require 'aws-sdk'

dbDoc = new AWS.DynamoDB.DocumentClient()

exports.handler = (event, context) ->
	console.log JSON.stringify(event, null, 2)
	params =
		Key:
			id: event.reportID
		TableName: '404_Reports'
	dbDoc.get params, (err, data) ->
		context.done err, data.Item
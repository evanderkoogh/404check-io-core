AWS = require 'aws-sdk'

exports.saveResults = (results, cb) ->
	params = transformResultsToParams results
	console.log "Saving: #{results.url}"
	db = new AWS.DynamoDB()
	db.putItem params, (err, data) ->
		console.log err if err
		cb err

transformResultsToParams = (results) ->
	params =
		Item:
			report_id:
				S: results.report_id
			url:
				S: results.url
			statusCode:
				S: results.statusCode?.toString()
			results:
				M: {}
			time:
				N: Date.now().toString()
			time_str:
				S: new Date().toUTCString()
		TableName: '404_Results'
		ReturnConsumedCapacity: 'INDEXES'
	for link_url, result of results.links
		obj =
			S: result.toString()
		params.Item.results.M[link_url] = obj

	return params
rm 404check.zip
coffee -c *.coffee
zip -q -r 404check.zip *
aws lambda update-function-code --function-name 404_getReport --zip-file fileb://404check.zip
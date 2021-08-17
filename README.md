# system-metric-service
POC of how to store and retrieve various system metrics with AWS services.

Coming soon

## Notes

### Lambda Package
```
pip3 install -t . redis
zip -r lambda_function.zip .
```

### AWS CLI
```
aws apigatewayv2 get-apis
aws lambda list-functions
aws lambda get-policy --function-name get_shard_metrics | jq
```

### Terraform
```
terraform fmt
terraform verify
terraform validate
terraform apply
```

## Todo
* Seems like the last piece is to add the resource based policy to give apigateway.amazonaws.com
 lambda:InvokeFunction access.
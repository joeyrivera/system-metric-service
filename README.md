# system-metric-service
POC of how to store and retrieve various system metrics with AWS services.

Coming soon

### Sample Response
```json
{
  "ip-172-30-0-180.ec2.internal": {
    "cpu_user_time": "644.07",
    "cpu_system_time": "397.74",
    "timestamp": "1628909579.7433248",
    "cpu_idle_time": "37532.24",
    "cpu_iowait_time": "9.34",
    "memory_virtual_total": "1031057408",
    "memory_virtual_available": "393969664",
    "memory_virtual_used": "497152000"
  }
}
```

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
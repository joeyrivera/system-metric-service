output "arn" {
  value = aws_elasticache_replication_group.metrics_redis.arn
}

output "primary_endpoint_address" {
  value = aws_elasticache_replication_group.metrics_redis.primary_endpoint_address
}

output "reader_endpoint_address" {
  value = aws_elasticache_replication_group.metrics_redis.reader_endpoint_address
}

output "api_lambda_source" {
  value = aws_lambda_permission.lambda_permission.source_arn
}

output "api_gateway_address" {
  value = aws_apigatewayv2_stage.resource_metric_service_stage.invoke_url
}
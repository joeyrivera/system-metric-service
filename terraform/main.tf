terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

resource "aws_elasticache_subnet_group" "elasticache_metric_subnet_group" {
  name       = "elasticache-metric-subnet-group"
  subnet_ids = var.subnet_ids
  tags = {
    Name = "ResourceMetricService"
  }
}

resource "aws_key_pair" "resource_metric_service" {
  key_name   = "resource-metric-service-key"
  public_key = var.ssh_key

  tags = {
    Name = "ResourceMetricService"
  }
}

resource "aws_security_group" "ec2_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH"
  vpc_id      = var.vpc_id

  ingress = [{
    prefix_list_ids  = []
    security_groups  = []
    description      = "SSH from public"
    from_port        = 22
    to_port          = 22
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    protocol         = "tcp"
    self             = true
  }]
}

resource "aws_instance" "app_server" {
  ami                    = var.ami
  instance_type          = "t2.micro"
  vpc_security_group_ids = [var.vpc_security_group_id, "${aws_security_group.ec2_ssh.id}"]
  subnet_id              = var.subnet_id
  key_name               = "resource-metric-service-key"

  depends_on = [aws_security_group.ec2_ssh]

  tags = {
    Name = "ResourceMetricService"
  }
}

resource "aws_iam_role" "lambda_metrics_vpc_role" {
  name                = "lambda_vpc_role"
  description         = "Allows Lambda functions to call AWS services on your behalf."
  assume_role_policy  = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"]
  tags = {
    Name = "ResourceMetricService"
  }
}

data "archive_file" "lambda_get_data_function" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/get_data/"
  output_path = "${path.module}/.terraform/archive_files/lambda_function_get_data_payload.zip"
}

resource "aws_elasticache_replication_group" "metrics_redis" {
  automatic_failover_enabled    = true
  availability_zones            = ["us-east-1d", "us-east-1a"]
  replication_group_id          = "metrics-redis"
  replication_group_description = "Metric redis group"
  node_type                     = "cache.t2.micro"
  number_cache_clusters         = 2
  parameter_group_name          = "default.redis6.x"
  port                          = 6379
  security_group_ids            = [var.vpc_security_group_id]
  subnet_group_name             = aws_elasticache_subnet_group.elasticache_metric_subnet_group.name
  tags = {
    Name = "ResourceMetricService"
  }
}

resource "aws_lambda_function" "get_shard_health" {
  filename         = data.archive_file.lambda_get_data_function.output_path
  description      = "Gets metrics for a shard"
  function_name    = "get_shard_metrics"
  role             = aws_iam_role.lambda_metrics_vpc_role.arn
  source_code_hash = filebase64sha256(data.archive_file.lambda_get_data_function.output_path)
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.8"
  vpc_config {
    subnet_ids         = [var.subnet_id]
    security_group_ids = [var.vpc_security_group_id]
  }
  environment {
    variables = {
      redis_host = aws_elasticache_replication_group.metrics_redis.reader_endpoint_address
    }
  }
  depends_on = [aws_elasticache_replication_group.metrics_redis]
}

resource "aws_apigatewayv2_api" "resource_metric_service" {
  name          = "resource_metric_service"
  protocol_type = "HTTP"

  tags = {
    Name = "ResourceMetricService"
  }
}

resource "aws_apigatewayv2_stage" "resource_metric_service_stage" {
  api_id = aws_apigatewayv2_api.resource_metric_service.id
  name   = "$default"
  tags = {
    Name = "ResourceMetricService"
  }
}

resource "aws_apigatewayv2_integration" "lambda_integration_get" {
  api_id           = aws_apigatewayv2_api.resource_metric_service.id
  integration_type = "AWS_PROXY"

  connection_type    = "INTERNET"
  description        = "Lambda Integration"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.get_shard_health.invoke_arn

  request_parameters = {
    "overwrite:path" = "$request.path.shard"
  }
}

resource "aws_apigatewayv2_route" "get_shard_health_route" {
  api_id    = aws_apigatewayv2_api.resource_metric_service.id
  route_key = "GET /shards/{shard}"

  target = "integrations/${aws_apigatewayv2_integration.lambda_integration_get.id}"
}

resource "aws_lambda_permission" "lambda_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_shard_health.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.resource_metric_service.execution_arn}/*/*/shards/{shard}"

}

resource "aws_apigatewayv2_deployment" "first_deploy" {
  api_id      = aws_apigatewayv2_route.get_shard_health_route.api_id
  description = "First deployment"

  triggers = {
    redeployment = "${timestamp()}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

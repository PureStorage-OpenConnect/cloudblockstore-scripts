
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "2.2.0"
    }

  }
}


provider "archive" {
  # Configuration options
}

provider "aws" {
  # access_key and secret_key can be excluded if you
  # have your creds setup in ~/.aws
  #   access_key = "ACCESS_KEY_HERE"
  #   secret_key = "SECRET_KEY_HERE"
  region = var.region
}


resource "aws_ssm_parameter" "api_client_private_key" {
  name  = "api_client_private_key"
  type  = "String"
  value = file(var.cbs_api_client_private_key)
}


resource "aws_iam_policy" "policy_for_lambda" {
  name = "policy_for_lambda"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses"
        ],
        "Resource" : "*",
        "Effect" : "Allow"
      },
      {
        "Effect" : "Allow",
        "Action" : "ssm:GetParameter",
        "Resource" : aws_ssm_parameter.api_client_private_key.arn
      }
    ]
  })

}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
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
}

resource "aws_iam_role_policy_attachment" "policy_attach" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.policy_for_lambda.arn
}

resource "aws_lambda_layer_version" "tf_lambda_layer" {
  s3_bucket           = "pure-storage-kb-solutions"
  s3_key              = "pure-python-lambda-layer/py-pure-client-runtime3.6.zip"
  layer_name          = "lambda_layer_name"
  compatible_runtimes = ["python3.6"]
}

resource "aws_lambda_function" "tf_lambda_function" {
  filename      = "pure_lambda_function.zip"
  function_name = var.function_name
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "lambda_function.lambda_handler"


  source_code_hash = filebase64sha256("pure_lambda_function.zip")

  runtime     = "python3.6"
  memory_size = "256"
  timeout     = "90"

  # Layers 
  layers = [aws_lambda_layer_version.tf_lambda_layer.arn]

  # VPC Configuration
  vpc_config {
    security_group_ids = var.vpc_security_group_ids
    subnet_ids         = var.vpc_subnet_ids



  }


  # Environment variables
  environment {
    variables = {
      CBS_IP            = var.cbs_ip
      CBS_USERNAME      = var.cbs_username
      CLIENT_ID         = var.cbs_api_client_id
      KEY_ID            = var.cbs_api_key_id
      CLIENT_API_ISSUER = var.cbs_api_issuer
    }
  }

  depends_on = [

    aws_lambda_layer_version.tf_lambda_layer,
    aws_iam_policy.policy_for_lambda,
    aws_iam_role.iam_for_lambda,
    aws_iam_role_policy_attachment.policy_attach
  ]

}


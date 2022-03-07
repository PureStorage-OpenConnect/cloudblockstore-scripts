# Lambda Function
output "lambda_function_arn" {
  description = "The ARN of the Lambda Function"
  value       = aws_lambda_function.tf_lambda_function.arn
}

# IAM Role
output "lambda_role_arn" {
  description = "The ARN of the IAM role created for the Lambda Function"
  value       = aws_iam_role.iam_for_lambda.arn
}
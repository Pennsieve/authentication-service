output "user_pool_id" {
  value = aws_cognito_user_pool.cognito_user_pool.id
}

output "user_pool_arn" {
  value = aws_cognito_user_pool.cognito_user_pool.arn
}

output "user_pool_client_id" {
  value = aws_cognito_user_pool_client.cognito_user_pool_client.id
}

output "user_pool_admin_client_id" {
  value = aws_cognito_user_pool_client.cognito_user_pool_admin_client.id
}

output "token_pool_id" {
  value = aws_cognito_user_pool.cognito_token_pool.id
}

output "token_pool_arn" {
  value = aws_cognito_user_pool.cognito_token_pool.arn
}

output "token_pool_client_id" {
  value = aws_cognito_user_pool_client.cognito_token_pool_client.id
}

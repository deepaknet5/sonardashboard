output "rds_endpoint" {
  value = aws_db_instance.default.endpoint
}

output "rds_username" {
  value = var.db_username
}

output "rds_db_name" {
  value = var.db_name
}

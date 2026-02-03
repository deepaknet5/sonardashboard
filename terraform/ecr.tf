resource "aws_ecr_repository" "sonar_dashboard" {
  name                 = "sonar-dashboard"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

output "ecr_repository_url" {
  value = aws_ecr_repository.sonar_dashboard.repository_url
}

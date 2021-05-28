output "domain_name" {
  description = "route53 record name"
  value       = aws_route53_record.route53_record.name
}

output "cloud_watch_log_group_arn" {
    description = "Log group arn"
    value = aws_cloudwatch_log_group.cloudwatch_log_group.arn
}
output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "configure_kubectl" {
  value = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

output "waf_acl_arn" {
  value = aws_wafv2_web_acl.alb.arn
}

output "audit_bucket" {
  value = aws_s3_bucket.audit.id
}

output "alerts_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

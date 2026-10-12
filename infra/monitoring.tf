resource "aws_sns_topic" "alerts" {
  name              = "${local.name}-security-alerts"
  kms_master_key_id = aws_kms_key.logs.arn
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

locals {
  trail_alarms = {
    root-account-usage = {
      description = "The root account was used"
      pattern     = <<-EOT
        { $.userIdentity.type = "Root" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != "AwsServiceEvent" }
      EOT
    }
    unauthorized-api-calls = {
      description = "Unauthorized or denied API calls"
      pattern     = <<-EOT
        { ($.errorCode = "*UnauthorizedOperation") || ($.errorCode = "AccessDenied*") }
      EOT
    }
    console-login-without-mfa = {
      description = "Console login without MFA"
      pattern     = <<-EOT
        { ($.eventName = "ConsoleLogin") && ($.additionalEventData.MFAUsed != "Yes") }
      EOT
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "trail" {
  for_each = local.trail_alarms

  name           = each.key
  pattern        = trimspace(each.value.pattern)
  log_group_name = aws_cloudwatch_log_group.trail.name

  metric_transformation {
    name      = each.key
    namespace = "${local.name}/Security"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "trail" {
  for_each = local.trail_alarms

  alarm_name          = "${local.name}-${each.key}"
  alarm_description   = each.value.description
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = each.key
  namespace           = "${local.name}/Security"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  depends_on = [aws_cloudwatch_log_metric_filter.trail]
}

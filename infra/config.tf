data "aws_iam_policy_document" "config_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "config" {
  name               = "${local.name}-config"
  assume_role_policy = data.aws_iam_policy_document.config_assume.json
}

resource "aws_iam_role_policy_attachment" "config_managed" {
  role       = aws_iam_role.config.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

data "aws_iam_policy_document" "config_s3" {
  statement {
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.audit.arn]
  }

  statement {
    actions   = ["s3:PutObject", "s3:PutObjectAcl"]
    resources = ["${aws_s3_bucket.audit.arn}/config/AWSLogs/${local.account_id}/Config/*"]
  }
}

resource "aws_iam_role_policy" "config_s3" {
  name   = "deliver-config-to-s3"
  role   = aws_iam_role.config.id
  policy = data.aws_iam_policy_document.config_s3.json
}

resource "aws_config_configuration_recorder" "main" {
  name     = "default"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "main" {
  name           = "default"
  s3_bucket_name = aws_s3_bucket.audit.id
  s3_key_prefix  = "config"

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.main]
}

locals {
  config_rules = {
    cloudtrail-enabled        = "CLOUD_TRAIL_ENABLED"
    root-account-mfa          = "ROOT_ACCOUNT_MFA_ENABLED"
    s3-public-read-prohibited = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
    encrypted-volumes         = "ENCRYPTED_VOLUMES"
    incoming-ssh-disabled     = "INCOMING_SSH_DISABLED"
    vpc-flow-logs-enabled     = "VPC_FLOW_LOGS_ENABLED"
    eks-secrets-encrypted     = "EKS_SECRETS_ENCRYPTED"
  }
}

resource "aws_config_config_rule" "managed" {
  for_each = local.config_rules

  name = "${local.name}-${each.key}"

  source {
    owner             = "AWS"
    source_identifier = each.value
  }

  depends_on = [aws_config_configuration_recorder_status.main]
}

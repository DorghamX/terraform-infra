# Security decisions

## Design decisions

| Decision | Reason |
|---|---|
| Private worker nodes with NAT egress | Nodes are never reachable from the internet |
| IRSA for the load balancer controller | Least privilege, no node-wide permissions |
| Dedicated network ACLs | Second network layer next to security groups |
| Customer managed KMS key with rotation | Control over log and alert encryption |
| Locked-down default security group | The module removes all default rules so nothing falls back to it |
| IMDSv2 required with hop limit 1 | Blocks pods from reading node instance credentials |
| CloudTrail streamed to CloudWatch Logs | Metric filters and alarms can watch API activity in near real time |
| ECR immutable tags with scan on push | A pushed tag cannot be overwritten and images are scanned automatically |
| CloudTrail log file validation | Detects deletion or modification of delivered log files |
| S3 gateway endpoint | Private subnet traffic to S3 stays on the AWS network and is free |
| GuardDuty EKS audit log feature enabled | Threat detection covers Kubernetes API activity |
| `force_destroy = true` on the audit bucket | Intentional so a lab can be destroyed cleanly. Remove it in production so audit evidence cannot be deleted with the stack |

## Accepted trade-offs

| Item | Why it is accepted | Production alternative |
|---|---|---|
| Single NAT gateway | Lower cost in a lab | One NAT per AZ (`single_nat_gateway = false`) |
| Public EKS API endpoint | Simple access for a lab | Restrict `api_allowed_cidrs` or use a private endpoint |
| Audit bucket uses SSE-S3 | Simplest reliable delivery for CloudTrail and Config | SSE-KMS with an extended key policy |
| `force_destroy` on audit bucket and ECR | Lab can be destroyed cleanly | Remove it and enable replication |
| IMDS hop limit 1 | Blocks pod access to node credentials | Raise only if a workload needs it |
| Log retention 30 days | Keeps cost low while the stack is a lab | Set `log_retention_days` to 365 or more to satisfy long term retention policies |
| `api_allowed_cidrs` defaults to `0.0.0.0/0` | The owner has no fixed lab IP yet | Set it to your own `/32` before creating a real cluster |

## Checkov skips

| Check ID | Reason | Alternative |
|---|---|---|
| CKV_TF_1 | Registry modules are pinned to exact versions as this guide requires, git commit pinning would conflict with that pinning strategy | Pin each module to an exact version or a git URL with a commit hash |
| CKV_AWS_338 | Retention is driven by `log_retention_days` (default 30 days) as this guide specifies, 1 year retention costs more in a lab | Set `log_retention_days` to 365 or more |
| CKV_AWS_252 | Alerts are delivered by CloudWatch alarms on the streamed copy of the trail, a native trail digest topic duplicates them and needs extra KMS grants that cannot be tested in Phase A | Set `sns_topic` on `aws_cloudtrail.main` in Phase B |
| CKV_AWS_111 | Standard AWS key policy pattern: the account root principal needs `kms:*` or the key becomes unusable, this guide forbids simplifying these statements | Replace the root principal with a dedicated key administrators role |
| CKV_AWS_109 | Same key policy statement as CKV_AWS_111: account root full access is required for key administration, replacing it breaks log delivery | Scope administration to a dedicated key administrators role |
| CKV_AWS_356 | Same key policy statement: `resources = "*"` is acceptable because a KMS key policy applies to this one key only, scoping is done with key policy conditions | Add `kms:ViaService` and encryption context conditions |
| CKV2_AWS_62 | The audit bucket is written by CloudTrail and AWS Config, S3 event notifications would need a new destination resource outside this guide's scope, trail events already reach the alarms | Add EventBridge rules or S3 notifications to a dedicated destination |
| CKV2_AWS_31 | WAF log destinations need a CloudWatch resource policy that cannot be validated without an AWS account, untested apply risk in Phase A | Add `logging_configuration` with a log group and resource policy in Phase B |
| CKV2_AWS_5 | The security group attaches to interface endpoint ENIs only when `enable_interface_endpoints` is true, which is off by default for cost, so nothing attaches in the default plan | Set `enable_interface_endpoints = true` |
| CKV_AWS_145 | Lab: audit bucket uses SSE-S3 for the simplest reliable CloudTrail and Config delivery | SSE-KMS with an extended key policy |
| CKV_AWS_144 | Lab single region: cross-region replication needs a second region bucket, cost and scope beyond this phase | Add replication to a bucket in a second region |
| CKV_AWS_18 | Access logs for the audit bucket need a separate log bucket that this guide's single audit bucket design does not include, CloudTrail log file validation already detects tampering | Add a dedicated S3 access log bucket |
| CKV2_AWS_3 | Single account lab uses a regional GuardDuty detector, the check expects organization wide delegation which needs AWS Organizations and is out of scope for Phase A | Delegate GuardDuty administration to a security account |

Two findings were fixed in code instead of skipped: CKV_AWS_300 (the audit bucket lifecycle now aborts incomplete multipart uploads after 7 days) and CKV_AWS_192 (the WAF web ACL now includes the `AWSManagedRulesKnownBadInputsRuleSet` managed rule group, which carries the `Log4JRCE` rule for CVE-2021-44228).

## Known limitations

- GuardDuty, Security Hub and AWS Config fail to create if the account already has them enabled.
- The stack has been validated and scanned only. It has not been applied.

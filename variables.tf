variable "feature_set" {
  description = "AWS Organizations feature set. ALL = full features (SCPs, tag policies, etc.). CONSOLIDATED_BILLING = billing-only. Downgrading from ALL to CONSOLIDATED_BILLING requires destroy/recreate."
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ALL", "CONSOLIDATED_BILLING"], var.feature_set)
    error_message = "feature_set must be either \"ALL\" or \"CONSOLIDATED_BILLING\"."
  }
}

variable "enabled_policy_types" {
  description = "Policy types to enable at the org root. A policy type must be enabled before any policy of that type can be attached."
  type        = list(string)
  default = [
    "SERVICE_CONTROL_POLICY",
    "TAG_POLICY",
    "BACKUP_POLICY",
    "AISERVICES_OPT_OUT_POLICY",
  ]

  validation {
    condition = alltrue([
      for t in var.enabled_policy_types : contains([
        "SERVICE_CONTROL_POLICY",
        "TAG_POLICY",
        "BACKUP_POLICY",
        "AISERVICES_OPT_OUT_POLICY",
        "CHATBOT_POLICY",
        "DECLARATIVE_POLICY_EC2",
        "RESOURCE_CONTROL_POLICY",
      ], t)
    ])
    error_message = "enabled_policy_types contains an unknown value. Valid values are: SERVICE_CONTROL_POLICY, TAG_POLICY, BACKUP_POLICY, AISERVICES_OPT_OUT_POLICY, CHATBOT_POLICY, DECLARATIVE_POLICY_EC2, RESOURCE_CONTROL_POLICY."
  }
}

variable "aws_service_access_principals" {
  description = "AWS services authorized to integrate with the Organization. Pre-enables the service-linked roles required by common services. Removing a principal from an active org can break service-linked roles already in use — review impact before removing."
  type        = list(string)
  default = [
    "sso.amazonaws.com",
    "config.amazonaws.com",
    "guardduty.amazonaws.com",
    "securityhub.amazonaws.com",
    "cloudtrail.amazonaws.com",
    "controltower.amazonaws.com",
    "ram.amazonaws.com",
    "access-analyzer.amazonaws.com",
  ]
}

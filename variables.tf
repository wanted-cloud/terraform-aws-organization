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

variable "organizational_units" {
  description = "OU tree defined as a flat map. Each entry's `parent` references another entry's KEY (not name) in this same map, or null for root-level OUs. OU depth is capped at 5 levels (AWS hard limit) and sibling OU names must be unique within their parent."
  type = map(object({
    name   = string
    parent = optional(string, null)
    tags   = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.organizational_units :
      v.parent == null || contains(keys(var.organizational_units), v.parent)
    ])
    error_message = "Each OU's `parent` must be null (root-level) or reference another key present in var.organizational_units."
  }

  validation {
    # Walk up to 5 parent links for each entry. If a 6th hop still resolves to a non-null parent, the depth limit is breached.
    # Root is level 0; an entry with parent=null is at depth 1; AWS allows at most 5 levels of OUs under root.
    condition = alltrue([
      for k, v in var.organizational_units : (
        v.parent == null ? true :
        try(var.organizational_units[v.parent].parent, null) == null ? true :
        try(var.organizational_units[var.organizational_units[v.parent].parent].parent, null) == null ? true :
        try(var.organizational_units[var.organizational_units[var.organizational_units[v.parent].parent].parent].parent, null) == null ? true :
        try(var.organizational_units[var.organizational_units[var.organizational_units[var.organizational_units[v.parent].parent].parent].parent].parent, null) == null
      )
    ])
    error_message = "OU tree depth exceeds the AWS limit of 5 levels. Reduce nesting under the deepest OU before applying."
  }

  validation {
    # Group entries by their parent key ("__root__" for root-level entries) and assert each group has unique `name` values.
    condition = alltrue([
      for parent_key in distinct([for v in var.organizational_units : coalesce(v.parent, "__root__")]) :
      length([for v in var.organizational_units : v.name if coalesce(v.parent, "__root__") == parent_key]) ==
      length(distinct([for v in var.organizational_units : v.name if coalesce(v.parent, "__root__") == parent_key]))
    ])
    error_message = "Sibling OUs must have unique `name` values within the same parent. Rename the duplicates or move them under different parents."
  }
}

variable "tags" {
  description = "Tags applied to every OU created by this module. Merged with module-level tags from metadata and any per-OU tags."
  type        = map(string)
  default     = {}
}

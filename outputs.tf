output "id" {
  description = "AWS Organization identifier."
  value       = aws_organizations_organization.this.id
}

output "arn" {
  description = "AWS Organization ARN."
  value       = aws_organizations_organization.this.arn
}

output "master_account_id" {
  description = "Management account ID."
  value       = aws_organizations_organization.this.master_account_id
}

output "master_account_arn" {
  description = "Management account ARN."
  value       = aws_organizations_organization.this.master_account_arn
}

output "master_account_email" {
  description = "Management account email."
  value       = aws_organizations_organization.this.master_account_email
}

output "root_id" {
  description = "Root OU identifier — the implicit top-level OU under the org. Use as parent for top-level OUs created outside this module."
  value       = aws_organizations_organization.this.roots[0].id
}

output "root_arn" {
  description = "Root OU ARN."
  value       = aws_organizations_organization.this.roots[0].arn
}

output "organizational_units" {
  description = "Map of created OUs keyed by input key. Each entry exposes id, arn, name, and parent_id."
  value = {
    for k, ou in aws_organizations_organizational_unit.this : k => {
      id        = ou.id
      arn       = ou.arn
      name      = ou.name
      parent_id = ou.parent_id
    }
  }
}

output "enabled_policy_types" {
  description = "Pass-through of the policy types enabled at the org root. Downstream policy modules (T1.03) read this to confirm a type is usable before attaching policies of that type."
  value       = var.enabled_policy_types
}

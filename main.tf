/*
 * # wanted-cloud/terraform-aws-organization
 *
 * Terraform building block managing the AWS Organization and its OU tree.
 */

resource "aws_organizations_organization" "this" {
  feature_set                   = var.feature_set
  enabled_policy_types          = var.enabled_policy_types
  aws_service_access_principals = var.aws_service_access_principals
}

resource "aws_organizations_organizational_unit" "this" {
  for_each = var.organizational_units

  name = each.value.name

  parent_id = each.value.parent == null ? aws_organizations_organization.this.roots[0].id : aws_organizations_organizational_unit.this[each.value.parent].id

  tags = merge(local.metadata.tags, var.tags, each.value.tags)
}

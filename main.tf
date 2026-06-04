/*
 * # wanted-cloud/terraform-aws-organization
 *
 * Terraform building block managing the AWS Organization (root-only).
 * The OU tree has moved to terraform-aws-organization-unit.
 */

resource "aws_organizations_organization" "this" {
  feature_set                   = var.feature_set
  enabled_policy_types          = var.enabled_policy_types
  aws_service_access_principals = var.aws_service_access_principals
}

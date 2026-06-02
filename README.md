<!-- BEGIN_TF_DOCS -->
# wanted-cloud/terraform-aws-organization

Terraform building block managing the AWS Organization and its OU tree.

## Table of contents

- [Requirements](#requirements)
- [Providers](#providers)
- [Variables](#inputs)
- [Outputs](#outputs)
- [Resources](#resources)
- [Usage](#usage)
- [Importing existing resources](#importing-existing-resources)
- [Gotchas](#gotchas)
- [Contributing](#contributing)

## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement\_aws) (~> 5.0)

## Providers

The following providers are used by this module:

- <a name="provider_aws"></a> [aws](#provider\_aws) (5.100.0)

## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_aws_service_access_principals"></a> [aws\_service\_access\_principals](#input\_aws\_service\_access\_principals)

Description: AWS services authorized to integrate with the Organization. Pre-enables the service-linked roles required by common services. Removing a principal from an active org can break service-linked roles already in use — review impact before removing.

Type: `list(string)`

Default:

```json
[
  "sso.amazonaws.com",
  "config.amazonaws.com",
  "guardduty.amazonaws.com",
  "securityhub.amazonaws.com",
  "cloudtrail.amazonaws.com",
  "controltower.amazonaws.com",
  "ram.amazonaws.com",
  "access-analyzer.amazonaws.com"
]
```

### <a name="input_enabled_policy_types"></a> [enabled\_policy\_types](#input\_enabled\_policy\_types)

Description: Policy types to enable at the org root. A policy type must be enabled before any policy of that type can be attached.

Type: `list(string)`

Default:

```json
[
  "SERVICE_CONTROL_POLICY",
  "TAG_POLICY",
  "BACKUP_POLICY",
  "AISERVICES_OPT_OUT_POLICY"
]
```

### <a name="input_feature_set"></a> [feature\_set](#input\_feature\_set)

Description: AWS Organizations feature set. ALL = full features (SCPs, tag policies, etc.). CONSOLIDATED\_BILLING = billing-only. Downgrading from ALL to CONSOLIDATED\_BILLING requires destroy/recreate.

Type: `string`

Default: `"ALL"`

### <a name="input_metadata"></a> [metadata](#input\_metadata)

Description: Metadata definitions for the module, this is optional construct allowing override of the module defaults defintions of validation expressions, error messages, resource timeouts and default tags.

Type:

```hcl
object({
    resource_timeouts = optional(
      map(
        object({
          create = optional(string, "30m")
          read   = optional(string, "5m")
          update = optional(string, "30m")
          delete = optional(string, "30m")
        })
      ), {}
    )
    tags                     = optional(map(string), {})
    validator_error_messages = optional(map(string), {})
    validator_expressions    = optional(map(string), {})
  })
```

Default: `{}`

### <a name="input_organizational_units"></a> [organizational\_units](#input\_organizational\_units)

Description: OU tree defined as a flat map. Each entry's `parent` references another entry's KEY (not name) in this same map, or null for root-level OUs. OU depth is capped at 5 levels (AWS hard limit) and sibling OU names must be unique within their parent.

Type:

```hcl
map(object({
    name   = string
    parent = optional(string, null)
    tags   = optional(map(string), {})
  }))
```

Default: `{}`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: Tags applied to every OU created by this module. Merged with module-level tags from metadata and any per-OU tags.

Type: `map(string)`

Default: `{}`

## Outputs

The following outputs are exported:

### <a name="output_arn"></a> [arn](#output\_arn)

Description: AWS Organization ARN.

### <a name="output_enabled_policy_types"></a> [enabled\_policy\_types](#output\_enabled\_policy\_types)

Description: Pass-through of the policy types enabled at the org root. Downstream policy modules (T1.03) read this to confirm a type is usable before attaching policies of that type.

### <a name="output_id"></a> [id](#output\_id)

Description: AWS Organization identifier.

### <a name="output_master_account_arn"></a> [master\_account\_arn](#output\_master\_account\_arn)

Description: Management account ARN.

### <a name="output_master_account_email"></a> [master\_account\_email](#output\_master\_account\_email)

Description: Management account email.

### <a name="output_master_account_id"></a> [master\_account\_id](#output\_master\_account\_id)

Description: Management account ID.

### <a name="output_organizational_units"></a> [organizational\_units](#output\_organizational\_units)

Description: Map of created OUs keyed by input key. Each entry exposes id, arn, name, and parent\_id.

### <a name="output_root_arn"></a> [root\_arn](#output\_root\_arn)

Description: Root OU ARN.

### <a name="output_root_id"></a> [root\_id](#output\_root\_id)

Description: Root OU identifier — the implicit top-level OU under the org. Use as parent for top-level OUs created outside this module.

## Resources

The following resources are used by this module:

- [aws_organizations_organization.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organization) (resource)
- [aws_organizations_organizational_unit.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organizational_unit) (resource)

## Usage

> For more detailed examples navigate to `examples` folder of this repository.

Module was also published via Terraform Registry and can be used as a module from the registry.

```hcl
module "example" {
  source  = "wanted-cloud/organization/aws"
  version = "~> 0.1"
}
```

### Minimal — just the Org

```hcl
terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

module "org" {
  source = "../.."
}
```

### Enterprise — full OU tree

```hcl
terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

module "org" {
  source = "../.."

  organizational_units = {
    platform = {
      name = "Platform"
    }
    platform_connectivity = {
      name   = "Connectivity"
      parent = "platform"
    }
    platform_management = {
      name   = "Management"
      parent = "platform"
    }
    platform_identity = {
      name   = "Identity"
      parent = "platform"
    }
    workloads = {
      name = "Workloads"
    }
    workloads_dev = {
      name   = "Dev"
      parent = "workloads"
    }
    workloads_prod = {
      name   = "Prod"
      parent = "workloads"
    }
    sandbox = {
      name = "Sandbox"
    }
    decommissioned = {
      name = "Decommissioned"
    }
  }

  tags = {
    Owner       = "platform-team"
    Environment = "production"
  }
}

output "workloads_prod_ou_id" {
  description = "Identifier of the Workloads/Prod OU — pass to downstream account modules."
  value       = module.org.organizational_units["workloads_prod"].id
}
```

## Importing existing resources

When the management account already has an AWS Organization (brownfield), import the org and each pre-existing OU before the first `terraform apply`:

```bash
terraform import module.org.aws_organizations_organization.this o-xxxxxxxxxx
```

```bash
terraform import 'module.org.aws_organizations_organizational_unit.this["platform"]' ou-rootid-platformid
```

Repeat the second command for every OU declared in `var.organizational_units` that already exists in AWS, substituting the map key and the AWS OU id.

## Gotchas

Read these before applying in any account that matters.

| # | Gotcha | Mitigation |
|---|---|---|
| 1 | `aws_organizations_organization` is a singleton per management account. | Import an existing org with `terraform import` instead of letting the module try to create a second one. |
| 2 | Feature-set downgrade (`ALL` → `CONSOLIDATED_BILLING`) requires destroy/recreate. | Pin `feature_set = "ALL"` for production orgs and add `lifecycle { prevent_destroy = true }` in the caller if desired. |
| 3 | Policy types must be enabled BEFORE policies of that type are attached. | Downstream policy modules (T1.03) consume the `enabled_policy_types` output — keep that contract in mind when reducing the list. |
| 4 | Removing an entry from `aws_service_access_principals` can break service-linked roles already in use. | Never remove a principal from an active org without confirming no service depends on it. |
| 5 | OU tree depth is capped at 5 levels (AWS hard limit). | The `organizational_units` validator rejects trees deeper than 5 levels at plan time. |
| 6 | OU names must be unique within their parent (not globally). | The `organizational_units` validator groups entries by parent and rejects duplicate sibling names at plan time. |
| 7 | Org destruction is blocked if the org contains any account other than the management account. | Expected behaviour — move member accounts out first (T1.02) before destroying. |
| 8 | Service-linked role (SLR) creation can race on the first apply. | If apply fails because an SLR is still propagating, re-run after ~30 seconds (AWS-side eventual consistency). |

## Contributing

_Contributions are welcomed and must follow [Code of Conduct](https://github.com/wanted-cloud/.github?tab=coc-ov-file) and common [Contributions guidelines](https://github.com/wanted-cloud/.github/blob/main/docs/CONTRIBUTING.md)._

> If you'd like to report security issue please follow [security guidelines](https://github.com/wanted-cloud/.github?tab=security-ov-file).
---
<sup><sub>_2025 &copy; All rights reserved - WANTED.solutions s.r.o._</sub></sup>
<!-- END_TF_DOCS -->

# Migration Guide

> **Breaking change.** This release removes the OU resource from `terraform-aws-organization`. Treat the next tagged version as a major bump and plan your upgrade window accordingly.

## What changed

- `aws_organizations_organizational_unit.this` has been removed from this module.
- `var.organizational_units` (and its `parent` / depth / sibling-name validators) has been removed.
- The `organizational_units` output has been removed.
- `var.tags` has been removed — it only fed the (now-gone) OU resource. The `aws_organizations_organization` resource does not accept tags.

This module is now **AWS Organization root-only**. OU management has moved to a new sibling module: [`terraform-aws-organization-unit`](https://github.com/wanted-cloud/terraform-aws-organization-unit).

## Why

Splitting the Organization from the OU tree lets you:

- Manage the Organization and its OUs on independent lifecycles (e.g. recreate OUs without churning the org, or own the OUs from a different repo / pipeline).
- Compose Organization + OUs + Policies as three small modules — required by `terraform-aws-organization-policy` (T1.03), which expects to receive OU IDs as inputs.
- Keep each building block single-responsibility (one provider concern per module).

## Removed surface

| Surface | Status | Replacement |
|---|---|---|
| `aws_organizations_organizational_unit.this` resource | Removed | `terraform-aws-organization-unit` module |
| `var.organizational_units` | Removed | Inputs on the new `terraform-aws-organization-unit` module |
| `output.organizational_units` | Removed | Outputs on the new `terraform-aws-organization-unit` module |
| `var.tags` | Removed | Per-OU tags on the new module |

The retained outputs (`id`, `arn`, `master_account_id`, `master_account_arn`, `master_account_email`, `root_id`, `root_arn`, `enabled_policy_types`) are unchanged.

## Migration path A — `moved {}` block (recommended)

Use this path when you are adopting `terraform-aws-organization-unit` in the **same Terraform configuration** that already declares `module "org"`. Terraform will refactor the existing OU state in place, with **no destroy or recreate**.

1. Add the new module call alongside your existing org module:

   ```hcl
   module "org" {
     source  = "wanted-cloud/organization/aws"
     version = ">= 0.2.0"  # post-split release

     # organizational_units = { ... }   <-- remove this block
     # tags                 = { ... }   <-- remove if it only fed OUs
   }

   module "ous" {
     source  = "wanted-cloud/organization-unit/aws"
     version = "~> 0.1"

     root_id = module.org.root_id

     organizational_units = {
       platform = { name = "Platform" }
       workloads = { name = "Workloads" }
       workloads_prod = { name = "Prod", parent = "workloads" }
       # ... copy the entries that previously lived under module.org
     }

     tags = {
       Owner       = "platform-team"
       Environment = "production"
     }
   }
   ```

2. Add a `moved {}` block for every OU entry, mapping the old address to the new module address:

   ```hcl
   moved {
     from = module.org.aws_organizations_organizational_unit.this["platform"]
     to   = module.ous.aws_organizations_organizational_unit.this["platform"]
   }

   moved {
     from = module.org.aws_organizations_organizational_unit.this["workloads"]
     to   = module.ous.aws_organizations_organizational_unit.this["workloads"]
   }

   moved {
     from = module.org.aws_organizations_organizational_unit.this["workloads_prod"]
     to   = module.ous.aws_organizations_organizational_unit.this["workloads_prod"]
   }

   # ... repeat for every OU key in the original organizational_units map
   ```

3. Update any downstream references that read `module.org.organizational_units[...]` to read from the new module instead (typically `module.ous.organizational_units[...]`).

4. Run `terraform plan` and confirm **zero resource changes** — only the `moved` refactor entries.

5. Apply, then delete the `moved {}` blocks in a follow-up commit (optional housekeeping).

## Migration path B — `terraform state mv` (manual, no `moved` block)

Use this path if you cannot ship a single configuration change containing both modules (e.g. you are splitting the OUs into a different state file or workspace).

1. Pin the **pre-split** version of `terraform-aws-organization` in your config, run `terraform plan`, and confirm zero diff. This establishes a clean baseline.

2. In a separate change, remove `var.organizational_units` from the existing `module "org"` call **and** add the new `module "ous"` (or root config) referencing the new state.

3. For every OU in state, move it from the old address to the new address:

   ```bash
   terraform state mv \
     'module.org.aws_organizations_organizational_unit.this["platform"]' \
     'module.ous.aws_organizations_organizational_unit.this["platform"]'
   ```

   Repeat for every key that existed in the original `organizational_units` map.

   If you are moving OUs into a **different state file**, use the `-state` / `-state-out` flags:

   ```bash
   terraform state mv \
     -state=org/terraform.tfstate \
     -state-out=ous/terraform.tfstate \
     'module.org.aws_organizations_organizational_unit.this["platform"]' \
     'module.ous.aws_organizations_organizational_unit.this["platform"]'
   ```

4. Bump the `terraform-aws-organization` source version to the post-split release.

5. Run `terraform plan` in both the old and new configurations. Both must report **zero resource changes**.

## Verifying the migration

After either path, the success criterion is the same:

```bash
terraform plan
```

Expected output:

```
No changes. Your infrastructure matches the configuration.
```

If you see `aws_organizations_organizational_unit.this["..."] will be destroyed` or `... will be created`, **stop and investigate** — the state move did not land as expected. Roll back the configuration change, re-establish the baseline, and retry.

## Common pitfalls

| Symptom | Cause | Fix |
|---|---|---|
| `plan` shows OUs destroyed and recreated | `moved {}` block has a typo in the address, or `state mv` was skipped | Verify each `from` / `to` address character-for-character against `terraform state list` |
| `plan` shows OUs in the new module but old ones still exist | `moved` block only refactors state; the old declaration is still in the config | Remove `organizational_units = { ... }` from the old `module "org"` call |
| Tag drift after migration | Old `var.tags` on `module "org"` was wider than per-OU tags | Reapply the same tags via the new module's `tags` input (module-wide) or per-OU `tags` |
| Downstream module breaks on `module.org.organizational_units[...]` | The output was removed | Update the reference to the new module's output (`module.ous.organizational_units[...]`) |

## Versioning

This is a **breaking change**. The next release of `terraform-aws-organization` should be a major version bump (e.g. `v0.2.0`). Pin your callers to the previous minor (`v0.1.x`) until you have run through the migration steps above.

The user owns tagging and Registry publish — no tag is created as part of this refactor.

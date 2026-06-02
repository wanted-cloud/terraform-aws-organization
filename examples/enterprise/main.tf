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

locals {
  // Here you can define module metadata
  definitions = {
    tags = {
      ManagedBy             = "Terraform"
      "wanted-cloud:module" = "terraform-aws-organization"
      "wanted-cloud:tier"   = "T1.01"
    }
  }
}

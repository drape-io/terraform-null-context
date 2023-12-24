module "full" {
  source = "../../"
  group  = "drape"
  tenant = "customer1"
  scope  = "k8s"
  env    = "dev"
  tags   = {
    "Owner": "group-sre@test.com",
  }
}

output "tags" {
  value       = module.full.tags
  description = "Tags for the context"
}
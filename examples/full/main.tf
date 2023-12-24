module "full" {
  source = "../../"
  group  = "drape"
  tenant = "customer1"
  scope  = "k8s"
  env    = "dev"
  tags = {
    "Owner" : "group-sre@test.com",
  }
}

module "secondary" {
  source  = "../../"
  env     = "prd"
  context = module.full.context
}

output "context" {
  value       = module.full.context
  description = "Tags for the context"
}

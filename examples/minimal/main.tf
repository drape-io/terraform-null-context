terraform {
  required_version = ">= 1.6"
}

module "minimal" {
  source = "../../"
  group  = "foo"
}

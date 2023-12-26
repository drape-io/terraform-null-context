run "test_alphanumeric_validation" {
  command = plan

  variables {
    group = "foo-bar-$$"
  }

  expect_failures = [
    var.group
  ]
}

run "test_required_fields" {
  expect_failures = [
    check.validate_id_parts,
  ]
}

run "test_full_group" {
  variables {
    group = "drape"
  }
  assert {
    condition     = output.group == "drape"
    error_message = "group should be set"
  }
}

run "test_full_tenant" {
  variables {
    tenant = "customer1"
  }
  assert {
    condition     = output.tenant == "customer1"
    error_message = "tenant should be set"
  }
}

run "test_disabled_doesnt_output" {
  variables {
    enabled = false
    group   = "drape"
  }
  assert {
    condition     = output.group == ""
    error_message = "group shouldn't be set"
  }
}

run "test_id_full" {
  variables {
    group  = "drape"
    tenant = "customer"
    scope  = "k8s"
    env    = "prd"
  }
  assert {
    condition     = output.id_full == "drape-customer-prd-k8s"
    error_message = "id_full should include all parts"
  }
}

run "test_id_slash_full" {
  variables {
    group  = "drape"
    tenant = "customer"
    scope  = "k8s"
    env    = "prd"
  }
  assert {
    condition     = output.id_slash_full == "drape/customer/prd/k8s"
    error_message = "id_slash_full should include all parts"
  }
}


run "test_too_long_of_id" {
  variables {
    group  = "groupy-mcgrouperson-abcdefghijklmnopqrstuvwxyz"
    tenant = "customer-mccustomerson-abcdefghijklmnopqrstuvwxyz"
    scope  = "scoper-mcscoperson-abcdefghijklmnopqrstuvwxyz"
    env    = "production-mcproductionerson-abcdefghijklmnopqrstuvwxyz"
  }

  assert {
    condition     = length(output.id_truncated_fourty_hash) == 40
    error_message = "Truncation to fourty works"
  }

  assert {
    condition     = length(output.id_truncated_sixty_hash) == 60
    error_message = "Truncation to sixty works"
  }

  assert {
    condition     = length(output.id_truncated_one_twenty_hash) == 120
    error_message = "Truncation to one twenty works"
  }
}

run "test_id_full_with_attributes" {
  variables {
    group  = "drape"
    tenant = "customer"
    scope  = "k8s"
    env    = "prd"
    attributes = [
      "boom",
      "shaka",
      "laka",
    ]
  }
  assert {
    condition     = output.id_full == "drape-customer-prd-k8s-boom-shaka-laka"
    error_message = "id_full should include all parts"
  }
}

run "test_id_full_with_only_attributes" {
  variables {
    attributes = [
      "boom",
      "shaka",
      "laka",
    ]
  }
  assert {
    condition     = output.id_full == "boom-shaka-laka"
    error_message = "id_full should include all parts"
  }
}

run "test_tags" {
  variables {
    group  = "drape"
    tenant = "customer"
    scope  = "k8s"
    env    = "prd"
    tags = {
      "Owner" : "group-sre@test.com",
    }
    attributes = [
      "boom",
      "shaka",
      "laka",
    ]
  }
  assert {
    condition     = output.tags["Group"] == "drape"
    error_message = "Group wasn't in tags"
  }

  assert {
    condition     = output.tags["Tenant"] == "customer"
    error_message = "Tenant wasn't in tags"
  }

  assert {
    condition     = output.tags["Scope"] == "k8s"
    error_message = "Scope wasn't in tags"
  }

  assert {
    condition     = output.tags["Env"] == "prd"
    error_message = "Env wasn't in tags"
  }

  assert {
    condition     = output.tags["Owner"] == "group-sre@test.com"
    error_message = "Additional tags weren't in the tags output"
  }

  assert {
    condition = sort(keys(output.tags)) == sort([
      "Group", "Tenant", "Scope", "Env", "Owner"
    ])
    error_message = "Tags were invalid ${join(",", keys(output.tags))}"
  }
}

run "test_can_reuse_context" {
  variables {
    context = {
      group  = "drape"
      tenant = "customer"
      scope  = "k8s"
      env    = "prd"
      attributes = [
        "boom",
        "shaka",
        "laka",
      ]
    }
  }

  assert {
    condition     = output.context["group"] == "drape"
    error_message = "group wasn't in the context"
  }

  assert {
    condition     = output.context["tenant"] == "customer"
    error_message = "tenant wasn't in the context"
  }

  assert {
    condition     = output.context["env"] == "prd"
    error_message = "env wasn't in the context"
  }

  assert {
    condition     = sort(values(output.context["tags"])) == sort(["customer", "drape", "k8s", "prd"])
    error_message = "Group wasn't in context tags keys: ${join(",", keys(output.context["tags"]))} values: ${join(",", values(output.context["tags"]))}"
  }
}

run "test_can_reuse_and_override_context" {
  variables {
    tenant = "customer2"
    scope = ""

    context = {
      group  = "drape"
      tenant = "customer"
      scope  = "k8s"
      env    = "prd"
      attributes = [
        "boom",
        "shaka",
        "laka",
      ]
    }
  }

  assert {
    condition     = output.id_full == "drape-customer2-prd-boom-shaka-laka"
    error_message = "group wasn't in the context"
  }
}
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


run "test_too_long_of_id_fourty" {
  variables {
    group  = "groupy-mcgrouperson-abcdefghijklmnopqrstuvwxyz"
    tenant = "customer-mccustomerson-abcdefghijklmnopqrstuvwxyz"
    scope  = "scoper-mcscoperson-abcdefghijklmnopqrstuvwxyz"
    env    = "production-mcproductionerson-abcdefghijklmnopqrstuvwxyz"
    max_id_length = 40
  }

  assert {
    condition     = length(output.id_truncated_hash) == 40
    error_message = "Truncation to fourty works"
  }
}

run "test_too_long_of_id_one_twenty" {
  variables {
    group  = "groupy-mcgrouperson-abcdefghijklmnopqrstuvwxyz"
    tenant = "customer-mccustomerson-abcdefghijklmnopqrstuvwxyz"
    scope  = "scoper-mcscoperson-abcdefghijklmnopqrstuvwxyz"
    env    = "production-mcproductionerson-abcdefghijklmnopqrstuvwxyz"
    max_id_length = 120
  }

  assert {
    condition     = length(output.id_truncated_hash) == 120
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
      "owner" : "group-sre@test.com",
    }
    attributes = [
      "boom",
      "shaka",
      "laka",
    ]
  }
  assert {
    condition     = output.tags["group"] == "drape"
    error_message = "Group wasn't in tags"
  }

  assert {
    condition     = output.tags["tenant"] == "customer"
    error_message = "Tenant wasn't in tags"
  }

  assert {
    condition     = output.tags["scope"] == "k8s"
    error_message = "Scope wasn't in tags"
  }

  assert {
    condition     = output.tags["environment"] == "production"
    error_message = "Env wasn't in tags"
  }

  assert {
    condition     = output.tags["owner"] == "group-sre@test.com"
    error_message = "Additional tags weren't in the tags output, keys: ${join(",", keys(output.tags))}"
  }

  assert {
    condition = sort(keys(output.tags)) == sort([
      "group", "tenant", "scope", "environment", "owner", "managed-by"
    ])
    error_message = "Tags were invalid, keys: ${join(",", keys(output.tags))}"
  }
}

run "test_tags_casing_upper" {
  variables {
    group  = "drape"
    tenant = "customer"
    scope  = "k8s"
    env    = "prd"
    tag_key_case = "upper"
    tag_value_case = "upper"

    tags = {
      "owner" : "group-sre@test.com",
      "SERvICE": "AuthSvc"
    }
    attributes = [
      "boom",
      "shaka",
      "laka",
    ]
  }

  assert {
    condition     = output.tags["GROUP"] == "DRAPE"
    error_message = "GROUP wasn't in tags"
  }

  assert {
    condition     = output.tags["SERVICE"] == "AUTHSVC"
    error_message = "SERVICE wasn't in tags"
  }
}

run "test_tags_casing_title" {
  variables {
    group  = "drape"
    tenant = "customer"
    scope  = "k8s"
    env    = "prd"
    tag_key_case = "title"
    tag_value_case = null

    tags = {
      "owner" : "group-sre@test.com",
      "SERvICE": "AUTHSVC"
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
    condition     = output.tags["Service"] == "AUTHSVC"
    error_message = "Service wasn't in tags"
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
    condition     = sort(values(output.context["tags"])) == sort(["customer", "drape", "k8s", "production", "terraform"])
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

run "test_enabled_flag_false" {
  variables {
    tenant = "customer2"
    enabled = false
  }

  assert {
    condition     = output.enabled == false
    error_message = "enabled should've been false"
  }
}

run "test_enabled_flag" {
  variables {
    tenant = "customer2"
  }

  assert {
    condition     = output.enabled == true
    error_message = "enabled should've been true"
  }
}

run "test_enabled_through_context" {
  variables {
    tenant = "customer2"
    context = {
        enabled = false
    }
  }

  assert {
    condition     = output.enabled == false
    error_message = "enabled should've been false"
  }
}

run "test_can_override_tags_from_context" {
  variables {
    tenant = "customer2"
    context = {
        tags = {
            scope = "foo"
            tenant = "bar"
        }
    }
  }

  assert {
    condition     = output.tags["scope"] == "foo"
    error_message = "Scope wasn't included in tags"
  }
}
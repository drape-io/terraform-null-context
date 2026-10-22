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

run "test_too_long_of_id_forty" {
  variables {
    group         = "groupy-mcgrouperson-abcdefghijklmnopqrstuvwxyz"
    tenant        = "customer-mccustomerson-abcdefghijklmnopqrstuvwxyz"
    scope         = "scoper-mcscoperson-abcdefghijklmnopqrstuvwxyz"
    env           = "production-mcproductionerson-abcdefghijklmnopqrstuvwxyz"
    max_id_length = 40
  }

  assert {
    condition     = length(output.id_truncated_hash) == 40
    error_message = "Truncation to forty works"
  }

  assert {
    condition     = startswith(output.id_truncated_hash, output.id_truncated)
    error_message = "id_truncated_hash should start with id_truncated"
  }

  assert {
    condition     = length(output.id_truncated) == 40 - 8
    error_message = "id_truncated should leave 8 chars for the hash suffix"
  }
}

run "test_too_long_of_id_one_twenty" {
  variables {
    group         = "groupy-mcgrouperson-abcdefghijklmnopqrstuvwxyz"
    tenant        = "customer-mccustomerson-abcdefghijklmnopqrstuvwxyz"
    scope         = "scoper-mcscoperson-abcdefghijklmnopqrstuvwxyz"
    env           = "production-mcproductionerson-abcdefghijklmnopqrstuvwxyz"
    max_id_length = 120
  }

  assert {
    condition     = length(output.id_truncated_hash) == 120
    error_message = "Truncation to one twenty works"
  }

  assert {
    condition     = startswith(output.id_truncated_hash, output.id_truncated)
    error_message = "id_truncated_hash should start with id_truncated"
  }

  assert {
    condition     = length(output.id_truncated) == 120 - 8
    error_message = "id_truncated should leave 8 chars for the hash suffix"
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
    group          = "drape"
    tenant         = "customer"
    scope          = "k8s"
    env            = "prd"
    tag_key_case   = "upper"
    tag_value_case = "upper"

    tags = {
      "owner" : "group-sre@test.com",
      "SERvICE" : "AuthSvc"
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
    group          = "drape"
    tenant         = "customer"
    scope          = "k8s"
    env            = "prd"
    tag_key_case   = "title"
    tag_value_case = null

    tags = {
      "owner" : "group-sre@test.com",
      "SERvICE" : "AUTHSVC"
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
    scope  = ""

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
    tenant  = "customer2"
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
        scope  = "foo"
        tenant = "bar"
      }
    }
  }

  assert {
    condition     = output.tags["scope"] == "foo"
    error_message = "Scope wasn't included in tags"
  }
}

run "dont_send_tags_that_are_empty" {
  variables {
    tenant = "customer2"
  }

  assert {
    condition     = !contains(values(output.tags), "")
    error_message = "Tags were invalid, keys: ${join(",", keys(output.tags))}, values: ${join(",", values(output.tags))}"
  }
}

run "test_tag_key_case_inherited_from_context" {
  variables {
    group = "drape"
    env   = "prd"
    context = {
      tag_key_case = "upper"
    }
  }

  assert {
    condition     = contains(keys(output.tags), "GROUP")
    error_message = "tag_key_case should be inherited from context"
  }
}

run "test_tag_value_case_null_preserves_original" {
  variables {
    group          = "drape"
    env            = "prd"
    tag_value_case = null
    tags = {
      "owner" : "SRE-Team"
    }
  }

  assert {
    condition     = output.tags["owner"] == "SRE-Team"
    error_message = "null tag_value_case should preserve original casing"
  }
}

run "test_tag_casing_variable_overrides_context" {
  variables {
    group        = "drape"
    env          = "prd"
    tag_key_case = "lower"
    context = {
      tag_key_case = "upper"
    }
  }

  assert {
    condition     = output.tags["group"] == "drape"
    error_message = "Explicit tag_key_case should override context"
  }
}

run "test_custom_delimiter" {
  variables {
    group     = "drape"
    tenant    = "customer"
    scope     = "k8s"
    env       = "prd"
    delimiter = "_"
  }

  assert {
    condition     = output.id_full == "drape_customer_prd_k8s"
    error_message = "Custom delimiter should be used in id_full"
  }
}

run "test_no_random_string_when_no_truncation" {
  variables {
    group = "drape"
    env   = "prd"
  }

  assert {
    condition     = output.id_truncated_hash == output.id_full
    error_message = "id_truncated_hash should equal id_full when no truncation needed"
  }
}
# Ordinary inputs must keep producing the same names and tags.
run "test_pinned_env_scope" {
  variables {
    env   = "prd"
    scope = "app"
  }

  assert {
    condition     = output.id_full == "prd-app" && output.id_slash_full == "prd/app"
    error_message = "id changed: ${output.id_full} ${output.id_slash_full}"
  }

  assert {
    condition     = output.tags == tomap({ environment = "production", scope = "app", managed-by = "terraform" })
    error_message = "tags changed: ${jsonencode(output.tags)}"
  }
}

run "test_pinned_tenant_env" {
  variables {
    env    = "sbx"
    tenant = "sontek"
  }

  assert {
    condition     = output.id_full == "sontek-sbx" && output.id_slash_full == "sontek/sbx"
    error_message = "id changed: ${output.id_full} ${output.id_slash_full}"
  }

  assert {
    condition     = output.tags == tomap({ tenant = "sontek", environment = "sandbox", managed-by = "terraform" })
    error_message = "tags changed: ${jsonencode(output.tags)}"
  }
}

run "test_pinned_group_env_scope" {
  variables {
    group = "drp"
    env   = "mgmt"
    scope = "bootstrap"
  }

  assert {
    condition     = output.id_full == "drp-mgmt-bootstrap" && output.id_slash_full == "drp/mgmt/bootstrap"
    error_message = "id changed: ${output.id_full} ${output.id_slash_full}"
  }

  assert {
    condition     = output.tags == tomap({ group = "drp", environment = "mgmt", scope = "bootstrap", managed-by = "terraform" })
    error_message = "tags changed: ${jsonencode(output.tags)}"
  }
}

run "test_hash_is_deterministic_and_lowercase" {
  variables {
    group         = "groupy-mcgrouperson-abcdefghijklmnopqrstuvwxyz"
    tenant        = "customer-mccustomerson-abcdefghijklmnopqrstuvwxyz"
    max_id_length = 63
  }

  assert {
    condition     = output.id_truncated_hash == "${output.id_truncated}-${substr(sha256(output.id_full), 0, 7)}"
    error_message = "hash suffix should be the start of sha256(id_full): ${output.id_truncated_hash}"
  }

  assert {
    condition     = can(regex("^[a-z0-9-]{63}$", output.id_truncated_hash))
    error_message = "id_truncated_hash should be 63 lowercase chars: ${output.id_truncated_hash}"
  }
}

run "test_truncation_trims_trailing_delimiter" {
  variables {
    group         = "aaaaaaaaa"
    tenant        = "bbbbbbbbb"
    max_id_length = 18
  }

  assert {
    condition     = output.id_truncated == "aaaaaaaaa"
    error_message = "trailing delimiter should be trimmed: ${output.id_truncated}"
  }

  assert {
    condition     = length(output.id_truncated_hash) == 18 && !strcontains(output.id_truncated_hash, "--")
    error_message = "hash should fill the trimmed char: ${output.id_truncated_hash}"
  }
}

run "test_env_shorthand_any_case" {
  variables {
    env = "PRD"
  }

  assert {
    condition     = output.tags["environment"] == "production"
    error_message = "PRD should expand to production"
  }
}

run "test_child_of_upper_case_parent" {
  variables {
    env = "prd"
    context = {
      group        = "drape"
      tag_key_case = "upper"
      tags = {
        GROUP        = "DRAPE"
        ENVIRONMENT  = "DEVELOPMENT"
        "MANAGED-BY" = "TERRAFORM"
      }
    }
  }

  assert {
    condition     = output.tags["GROUP"] == "drape" && output.tags["ENVIRONMENT"] == "production"
    error_message = "child parts should win over inherited tags: ${jsonencode(output.tags)}"
  }
}

run "test_child_tags_merge_with_inherited" {
  variables {
    group = "drape"
    tags  = { team = "x" }
    context = {
      tags = { owner = "sre", environment = "development" }
    }
  }

  assert {
    condition     = output.tags["owner"] == "sre" && output.tags["team"] == "x" && output.tags["environment"] == "development"
    error_message = "inherited and own tags should both be kept: ${jsonencode(output.tags)}"
  }
}

run "test_user_tag_overrides_generated_key_in_other_case" {
  variables {
    env  = "prd"
    tags = { Environment = "Prod", owner = null }
  }

  assert {
    condition     = output.tags["environment"] == "prod" && !contains(keys(output.tags), "owner")
    error_message = "user tag should win and null tags should be dropped: ${jsonencode(output.tags)}"
  }
}

run "test_max_id_length_lower_bound" {
  command = plan

  variables {
    group         = "drape"
    max_id_length = 8
  }

  expect_failures = [var.max_id_length]
}

run "test_delimiter_allow_list" {
  command = plan

  variables {
    group     = "drape"
    delimiter = "/"
  }

  expect_failures = [var.delimiter]
}

run "test_context_parts_validated" {
  command = plan

  variables {
    context = { tenant = "acme/prd" }
  }

  expect_failures = [var.context]
}

run "test_attributes_validated" {
  command = plan

  variables {
    group      = "drape"
    attributes = ["prd/k8s"]
  }

  expect_failures = [var.attributes]
}

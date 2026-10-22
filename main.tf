locals {
  delimiter = var.delimiter

  env_full_names = {
    prd = "production"
    stg = "staging"
    dev = "development"
    prf = "performance"
    sbx = "sandbox"
    sec = "security"
  }

  # Attributes from context and variables are combined.
  attributes_list = compact(distinct(
    concat(
      coalesce(var.context.attributes, []),
      coalesce(var.attributes, [])
    )
  ))

  tag_key_case = coalesce(var.tag_key_case, var.context.tag_key_case, "lower")
  # null means "no transformation", so coalesce (which skips null) can't be used.
  tag_value_case = var.tag_value_case != null ? var.tag_value_case : var.context.tag_value_case

  # Variables take precedence over context when non-null. The string parts
  # cannot use coalesce: it skips "", and "" must override context.
  enabled    = coalesce(var.enabled, var.context.enabled, true)
  group      = var.group != null ? var.group : (var.context.group != null ? var.context.group : "")
  tenant     = var.tenant != null ? var.tenant : (var.context.tenant != null ? var.context.tenant : "")
  env        = var.env != null ? var.env : (var.context.env != null ? var.context.env : "")
  scope      = var.scope != null ? var.scope : (var.context.scope != null ? var.context.scope : "")
  tags       = coalesce(var.tags, var.context.tags, {})
  attributes = join(local.delimiter, local.attributes_list)

  parts_order = ["group", "tenant", "env", "scope", "attributes"]

  formatted = {
    group      = local.group
    tenant     = local.tenant
    env        = local.env
    scope      = local.scope
    attributes = local.attributes
  }

  provided_parts = [
    for p in local.parts_order : local.formatted[p] if length(local.formatted[p]) > 0
  ]

  id_full        = join(local.delimiter, local.provided_parts)
  id_slash_full  = join("/", local.provided_parts)
  id_full_length = length(local.id_full)

  # The env tag key becomes "environment" and its value expands through
  # env_full_names.
  tags_order = ["group", "tenant", "env", "scope"]
  generated_tags = merge(
    {
      for t in local.tags_order :
      t == "env" ? "environment" : t =>
      t == "env" ? lookup(local.env_full_names, local.formatted[t], local.formatted[t]) : local.formatted[t]
    },
    local.tags,
    {
      "managed-by" : "terraform"
    }
  )

  formatted_tags = {
    for k, v in local.generated_tags :
    local.tag_key_case == "lower" ? lower(k) :
    local.tag_key_case == "upper" ? upper(k) :
    # title() leaves mixed case like `FOOsBAR` as is, so lower first.
    local.tag_key_case == "title" ? title(lower(k)) : k
    =>
    local.tag_value_case == "lower" ? lower(v) :
    local.tag_value_case == "upper" ? upper(v) :
    local.tag_value_case == "title" ? title(v) :
    v
    # S3 buckets store no tags if any tag value is empty.
    if v != ""
  }

  # Only create the random hash (and its state) when the ID exceeds
  # max_id_length.
  hash_length       = 8
  needs_truncation  = local.id_full_length > var.max_id_length
  id_truncated      = local.needs_truncation ? substr(local.id_full, 0, var.max_id_length - local.hash_length) : local.id_full
  id_truncated_hash = local.needs_truncation ? "${local.id_truncated}${local.delimiter}${join("", random_string.hash_for_id[*].id)}" : local.id_full

  # Canonical context object. The outputs read from this directly.
  context = {
    enabled        = local.enabled
    group          = local.group
    tenant         = local.tenant
    env            = local.env
    scope          = local.scope
    attributes     = local.attributes_list
    tags           = local.formatted_tags
    tag_key_case   = local.tag_key_case
    tag_value_case = local.tag_value_case
  }
}

check "validate_id_parts" {
  assert {
    condition     = local.id_full_length > 0
    error_message = "Please provide at least one id part variable: ${join(",", local.parts_order)}"
  }
}

resource "random_string" "hash_for_id" {
  count = local.enabled && local.needs_truncation ? 1 : 0

  keepers = {
    full_id = local.id_full
  }
  length  = local.hash_length - length(local.delimiter)
  special = false
}

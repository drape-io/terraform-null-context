locals {
  delimiter = var.delimiter

  env_full_names = {
    prd = "production"
    stg = "staging"
    dev = "development"
    prf = "performance"
    sec = "security"
  }

  # Merge context and variable inputs — variables take precedence when non-null.
  # Direct field access (var.context.field) is used instead of lookup() since
  # the context variable is a typed object with optional() fields.
  attributes_list = compact(distinct(
    concat(
      coalesce(var.context.attributes, []),
      coalesce(var.attributes, [])
    )
  ))

  # tag_key_case: nullable so context passthrough works; defaults to "lower"
  tag_key_case = coalesce(var.tag_key_case, var.context.tag_key_case, "lower")
  # tag_value_case: null is a valid value meaning "no transformation", so we
  # cannot use coalesce (it would skip null and apply a default instead)
  tag_value_case = var.tag_value_case != null ? var.tag_value_case : var.context.tag_value_case

  enabled    = var.enabled != null ? var.enabled : (var.context.enabled != null ? var.context.enabled : true)
  group      = var.group != null ? var.group : (var.context.group != null ? var.context.group : "")
  tenant     = var.tenant != null ? var.tenant : (var.context.tenant != null ? var.context.tenant : "")
  env        = var.env != null ? var.env : (var.context.env != null ? var.context.env : "")
  scope      = var.scope != null ? var.scope : (var.context.scope != null ? var.context.scope : "")
  tags       = var.tags != null ? var.tags : (var.context.tags != null ? var.context.tags : {})
  attributes = join(local.delimiter, local.attributes_list)

  # Build ID
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

  id_validation_message = "Please provide at least one id part variable: ${join(",", local.parts_order)}"

  # Tags — key names are remapped (env -> environment) and env shorthand
  # values are expanded via the env_full_names lookup table.
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

  # Key and value casing use the same ternary pattern — HCL does not support
  # extracting reusable functions, so the duplication is intentional.
  formatted_tags = {
    for k in keys(local.generated_tags) :
    local.tag_key_case == "lower" ? lower(k) :
    local.tag_key_case == "upper" ? upper(k) :
    # Mixed casing like `FOOsBAR` doesn't let title work properly, so we lower
    # first to be consistent
    local.tag_key_case == "title" ? title(lower(k)) : k
    =>
    local.tag_value_case == "lower" ? lower(local.generated_tags[k]) :
    local.tag_value_case == "upper" ? upper(local.generated_tags[k]) :
    local.tag_value_case == "title" ? title(local.generated_tags[k]) :
    local.generated_tags[k]
    # S3 Buckets will not store any tags in the map if one of them has
    # an empty value
    if local.generated_tags[k] != ""
  }

  # Truncation — only allocate a random hash when the ID actually exceeds
  # max_id_length, avoiding unnecessary state for the common case.
  hash_length          = 8
  needs_truncation     = local.id_full_length > var.max_id_length
  id_truncation_length = local.needs_truncation ? local.id_full_length - (var.max_id_length - local.hash_length) : 0
  id_truncated         = substr(local.id_full, 0, local.id_full_length - local.id_truncation_length)
  id_truncated_hash    = local.needs_truncation ? "${local.id_truncated}${local.delimiter}${join("", random_string.hash_for_id[*].id)}" : local.id_full

  # Canonical context object — single source of truth.  The outputs reference
  # this directly, eliminating the prior duplication between return.* and
  # return.context.*.
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
    error_message = local.id_validation_message
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

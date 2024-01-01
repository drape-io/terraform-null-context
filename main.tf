locals {
  attributes_list = compact(distinct(
    concat(
      coalesce(lookup(var.context, "attributes", []), []),
      coalesce(var.attributes, [])
    )
  ))
  context_enabled = lookup(var.context, "enabled", true) == null ? true : var.context.enabled
  tag_key_case    = var.tag_key_case == null ? lookup(var.context, "tag_key_case", "lower") : var.tag_key_case
  tag_value_case  = var.tag_value_case == null ? lookup(var.context, "tag_value_case", "lower") : var.tag_value_case

  defaults = {
    enabled    = var.enabled == null ? local.context_enabled : var.enabled
    group      = var.group == null ? lookup(var.context, "group", "") : var.group
    tenant     = var.tenant == null ? lookup(var.context, "tenant", "") : var.tenant
    env        = var.env == null ? lookup(var.context, "env", "") : var.env
    scope      = var.scope == null ? lookup(var.context, "scope", "") : var.scope
    tags       = var.tags == null ? lookup(var.context, "tags", {}) : var.tags
    attributes = join("-", local.attributes_list)
  }

  parts_order = ["group", "tenant", "env", "scope", "attributes"]

  # The values still could be null when defining defaults so we normalize them
  # to empty strings here.
  formatted = { for k in local.parts_order : k =>
    local.defaults[k] == null ? "" : local.defaults[k]
  }
  provided_parts = [
    for p in local.parts_order : local.formatted[p] if length(local.formatted[p]) > 0
  ]

  id_full        = join("-", local.provided_parts)
  id_slash_full  = join("/", local.provided_parts)
  id_full_length = length(local.id_full)

  # TODO: I prefer the check below but it warns, doesn't fail.   I like this hack
  # because it blows up in your face. But its not easy to verify a test against.
  id_validation_message = "Please provide at least one id part variable: ${join(",", local.parts_order)}"
  # validate_id = local.id_full_length == 0 ? tobool(local.id_validation_message) : true

  tags_order = ["group", "tenant", "env", "scope"]
  generated_tags = merge(
    {
      for t in local.tags_order :
      t == "env" ? "environment" :
      t =>
      t == "env" && local.formatted[t] == "prd" ? "production" :
      t == "env" && local.formatted[t] == "stg" ? "staging" :
      t == "env" && local.formatted[t] == "dev" ? "development" :
      t == "env" && local.formatted[t] == "prf" ? "performance" :
      t == "env" && local.formatted[t] == "sec" ? "security" :
      local.formatted[t]
    },
    local.defaults.tags,
    {
      "managed-by" : "terraform"
    }
  )

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
}

check "validate_id_parts" {
  assert {
    condition     = local.id_full_length > 0
    error_message = local.id_validation_message
  }
}

locals {
  hash_length          = 8
  id_truncation_length = local.id_full_length > var.max_id_length ? local.id_full_length - (var.max_id_length - local.hash_length) : 0
  id_truncated         = substr(local.id_full, 0, local.id_full_length - local.id_truncation_length)
}


resource "random_string" "hash_for_id" {
  count = local.defaults.enabled ? 1 : 0

  keepers = {
    full_id = local.id_full
  }
  length  = local.hash_length - 1 # we'll add a hyphen in later
  special = false
}

locals {
  return = {
    enabled    = local.defaults.enabled
    group      = local.defaults.group
    tenant     = local.defaults.tenant
    env        = local.defaults.env
    scope      = local.defaults.scope
    tags       = local.formatted_tags
    attributes = local.attributes_list
    # We repeat this so we can pass the context to other modules but we keep
    # the ones above so they are nicer to access.
    context = {
      enabled        = local.defaults.enabled
      group          = local.defaults.group
      tenant         = local.defaults.tenant
      env            = local.defaults.env
      scope          = local.defaults.scope
      attributes     = local.attributes_list
      tags           = local.formatted_tags
      tag_key_case   = local.tag_key_case
      tag_value_case = local.tag_value_case
    }
    id_full           = local.id_full
    id_slash_full     = local.id_slash_full
    id_truncated      = local.id_truncated
    id_truncated_hash = local.id_truncation_length > 0 ? "${local.id_truncated}-${resource.random_string.hash_for_id[0].id}" : local.id_full
  }
}

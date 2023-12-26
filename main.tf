locals {
  attributes_list = compact(distinct(
    concat(
      coalesce(lookup(var.context, "attributes", []), []),
      coalesce(var.attributes, [])
    )
  ))
  defaults = {
    enabled    = var.enabled == null ? var.context.enabled : var.enabled
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
  tags = merge({
    for k in local.tags_order : title(k) => local.defaults[k]
  }, local.defaults.tags)
}

check "validate_id_parts" {
  assert {
    condition     = local.id_full_length > 0
    error_message = local.id_validation_message
  }
}

locals {
  hash_length = 8

  id_fourty_truncation_length     = local.id_full_length > 40 ? local.id_full_length - (40 - local.hash_length) : 0
  id_sixty_truncation_length      = local.id_full_length > 60 ? local.id_full_length - (60 - local.hash_length) : 0
  id_one_twenty_truncation_length = local.id_full_length > 120 ? local.id_full_length - (120 - local.hash_length) : 0

  id_truncated_fourty     = substr(local.id_full, 0, local.id_full_length - local.id_fourty_truncation_length)
  id_truncated_sixty      = substr(local.id_full, 0, local.id_full_length - local.id_sixty_truncation_length)
  id_truncated_one_twenty = substr(local.id_full, 0, local.id_full_length - local.id_one_twenty_truncation_length)

}


resource "random_string" "hash_for_id" {
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
    tags       = local.tags
    attributes = local.attributes_list
    # We repeat this so we can pass the context to other modules but we keep
    # the ones above so they are nicer to access.
    context = {
      enabled    = local.defaults.enabled
      group      = local.defaults.group
      tenant     = local.defaults.tenant
      env        = local.defaults.env
      scope      = local.defaults.scope
      attributes = local.attributes_list
      tags       = local.tags
    }
    id_full                      = local.id_full
    id_slash_full                = local.id_slash_full
    id_truncated_fourty          = local.id_truncated_fourty
    id_truncated_sixty           = local.id_truncated_sixty
    id_truncated_one_twenty      = local.id_truncated_one_twenty
    id_truncated_fourty_hash     = local.id_fourty_truncation_length > 0 ? "${local.id_truncated_fourty}-${resource.random_string.hash_for_id.id}" : local.id_full
    id_truncated_sixty_hash      = local.id_sixty_truncation_length > 0 ? "${local.id_truncated_sixty}-${resource.random_string.hash_for_id.id}" : local.id_full
    id_truncated_one_twenty_hash = local.id_one_twenty_truncation_length > 0 ? "${local.id_truncated_one_twenty}-${resource.random_string.hash_for_id.id}" : local.id_full
  }
}

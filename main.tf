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
  attributes = join(local.delimiter, local.attributes_list)

  provided_parts = compact([local.group, local.tenant, local.env, local.scope, local.attributes])

  id_full        = join(local.delimiter, local.provided_parts)
  id_slash_full  = join("/", local.provided_parts)
  id_full_length = length(local.id_full)

  # Tags in increasing precedence: tags inherited through context, tags
  # generated from the ID parts (empty parts are skipped so they do not hide
  # inherited values), tags set on this module, then managed-by. Keys are cased
  # before they are combined, so inherited keys that are already cased match
  # the generated ones. The env value expands through env_full_names.
  generated_tags = {
    group       = local.group
    tenant      = local.tenant
    environment = lookup(local.env_full_names, lower(local.env), local.env)
    scope       = local.scope
  }

  tag_pairs = concat(
    [for k, v in coalesce(var.context.tags, {}) : { k = k, v = v }],
    [for k, v in local.generated_tags : { k = k, v = v } if v != ""],
    [for k, v in coalesce(var.tags, {}) : { k = k, v = v }],
    [{ k = "managed-by", v = "terraform" }],
  )

  # Group by cased key. Each group keeps list order, so the last value has the
  # highest precedence.
  cased_tags = {
    for p in local.tag_pairs :
    local.tag_key_case == "lower" ? lower(p.k) :
    local.tag_key_case == "upper" ? upper(p.k) :
    # title() leaves mixed case like `FOOsBAR` as is, so lower first.
    local.tag_key_case == "title" ? title(lower(p.k)) : p.k
    => p.v...
  }

  formatted_tags = {
    for k, vs in local.cased_tags :
    k =>
    local.tag_value_case == "lower" ? lower(vs[length(vs) - 1]) :
    local.tag_value_case == "upper" ? upper(vs[length(vs) - 1]) :
    local.tag_value_case == "title" ? title(vs[length(vs) - 1]) :
    vs[length(vs) - 1]
    # S3 buckets store no tags if any tag value is empty. Null values are
    # dropped too.
    if vs[length(vs) - 1] != null && vs[length(vs) - 1] != ""
  }

  # The hash is the start of sha256(id_full), so the same ID always gets the
  # same suffix. A trailing delimiter is trimmed from the truncated part, and
  # the hash grows to keep the total at max_id_length.
  hash_length      = 8
  needs_truncation = local.id_full_length > var.max_id_length
  id_truncated = (
    local.needs_truncation
    ? replace(substr(local.id_full, 0, var.max_id_length - local.hash_length), "/[-_.]+$/", "")
    : local.id_full
  )
  hash_suffix = substr(
    sha256(local.id_full),
    0,
    min(64, var.max_id_length - length(local.id_truncated) - length(local.delimiter)),
  )
  id_truncated_hash = local.needs_truncation ? "${local.id_truncated}${local.delimiter}${local.hash_suffix}" : local.id_full

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
    error_message = "Please provide at least one id part variable: group,tenant,env,scope,attributes"
  }
}

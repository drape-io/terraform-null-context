output "enabled" {
  value       = local.context.enabled
  description = "Whether the module is enabled"
}

output "group" {
  value       = local.context.enabled ? local.context.group : ""
  description = "The defined group"
}

output "tenant" {
  value       = local.context.enabled ? local.context.tenant : ""
  description = "The defined tenant"
}

output "id_full" {
  value       = local.context.enabled ? local.id_full : ""
  description = "The full ID"
}

output "id_slash_full" {
  value       = local.context.enabled ? local.id_slash_full : ""
  description = "The ID with `/` between the parts"
}

output "id_truncated" {
  value       = local.context.enabled ? local.id_truncated : ""
  description = "The part of the ID kept before the hash suffix: at most `max_id_length` minus 8 chars, without a trailing delimiter"
}

output "id_truncated_hash" {
  value       = local.context.enabled ? local.id_truncated_hash : ""
  description = "The ID, truncated to `max_id_length` with a hash suffix when it is longer"
}

output "tags" {
  value       = local.context.enabled ? local.context.tags : {}
  description = "The generated tags"
}

# Not gated on enabled, so a disabled parent can still pass its naming context
# to child modules that set their own enabled flag.
output "context" {
  value       = local.context
  description = "The context object to pass to another instance of this module"
}

output "enabled" {
  value       = local.context.enabled
  description = "If it was enabled or not"
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
  description = "The full ID with slashes"
}

output "id_truncated" {
  value       = local.context.enabled ? local.id_truncated : ""
  description = "The full ID truncated to `max_id_length` chars, leaving 8 for a hash"
}

output "id_truncated_hash" {
  value       = local.context.enabled ? local.id_truncated_hash : ""
  description = "The full ID truncated with a hash"
}

output "tags" {
  value       = local.context.enabled ? local.context.tags : {}
  description = "Tags for the context"
}

# The context output always passes through regardless of the enabled flag.
# This allows a disabled parent module's naming context to be reused by child
# modules that may independently control their own enabled state.
output "context" {
  value       = local.context
  description = "The full context object if you want to pass it to another module"
}

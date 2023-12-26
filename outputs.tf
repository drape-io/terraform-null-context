output "group" {
  value       = local.return.enabled ? local.return.group : ""
  description = "The defined group"
}

output "tenant" {
  value       = local.return.enabled ? local.return.tenant : ""
  description = "The defined tenant"
}

output "id_full" {
  value       = local.return.enabled ? local.return.id_full : ""
  description = "The full ID"
}

output "id_slash_full" {
  value       = local.return.enabled ? local.return.id_slash_full : ""
  description = "The full ID with slashes"
}

output "id_truncated" {
  value       = local.return.enabled ? local.return.id_truncated : ""
  description = "The full ID truncated to `max_id_length` chars, leaving 8 for a hash"
}

output "id_truncated_hash" {
  value       = local.return.enabled ? local.return.id_truncated_hash : ""
  description = "The full ID truncated with a hash"
}

output "tags" {
  value       = local.return.enabled ? local.return.tags : {}
  description = "Tags for the context"
}

output "context" {
  value       = local.return.context
  description = "The full context object if you want to pass it to another module"
}

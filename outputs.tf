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

output "id_truncated_fourty" {
  value       = local.return.enabled ? local.return.id_truncated_fourty : ""
  description = "The full ID truncated to 32 chars, leaving 8 for a hash"
}

output "id_truncated_fourty_hash" {
  value       = local.return.enabled ? local.return.id_truncated_fourty_hash : ""
  description = "The full ID truncated with a hash"
}

output "id_truncated_sixty_hash" {
  value       = local.return.enabled ? local.return.id_truncated_sixty_hash : ""
  description = "The full ID truncated to 52 chars, leaving 8 for a hash"
}

output "id_truncated_one_twenty_hash" {
  value       = local.return.enabled ? local.return.id_truncated_one_twenty_hash : ""
  description = "The full ID truncated to 112 chars, leaving 8 for a hash"
}

output "tags" {
  value       = local.return.enabled ? local.return.tags : {}
  description = "Tags for the context"
}

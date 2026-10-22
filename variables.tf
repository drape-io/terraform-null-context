variable "enabled" {
  type        = bool
  default     = null
  nullable    = true
  description = "Prevent the module from creating any resources if disabled."
}

variable "group" {
  type        = string
  default     = null
  nullable    = true
  description = <<-EOT
    A unique identifier for your resources.  This could be your organization
    name or an abbreviation
  EOT
  validation {
    condition     = var.group == null || can(regex("^[0-9A-Za-z-]*$", var.group))
    error_message = "Value can only be alphanumeric and hyphens."
  }
}

variable "tenant" {
  type        = string
  default     = null
  nullable    = true
  description = <<-EOT
    In a multi-tenant environment you can use this to identify which resources
    go where. You can also use this to link resources to individual developers
    in sandboxes.
  EOT
  validation {
    condition     = var.tenant == null || can(regex("^[0-9A-Za-z-]*$", var.tenant))
    error_message = "Value can only be alphanumeric and hyphens."
  }
}

variable "env" {
  type        = string
  default     = null
  nullable    = true
  description = <<-EOT
    Should be the type of environment for the resource (prd, stg, dev, prf, sbx, sec)
  EOT
  validation {
    condition     = var.env == null || can(regex("^[0-9A-Za-z-]*$", var.env))
    error_message = "Value can only be alphanumeric and hyphens."
  }
}

variable "scope" {
  type        = string
  default     = null
  nullable    = true
  description = <<-EOT
    Scope down the resource to a specific application or service in your
    environment
  EOT
  validation {
    condition     = var.scope == null || can(regex("^[0-9A-Za-z-]*$", var.scope))
    error_message = "Value can only be alphanumeric and hyphens."
  }
}

variable "attributes" {
  type        = list(string)
  default     = []
  description = <<-EOT
    Extra values to append to the end of the ID to make it unique.
    EOT
  validation {
    condition = alltrue([
      for a in coalesce(var.attributes, []) : a == null ? true : can(regex("^[0-9A-Za-z-]*$", a))
    ])
    error_message = "Attributes can only be alphanumeric and hyphens."
  }
}

variable "tags" {
  type        = map(string)
  default     = null
  nullable    = true
  description = <<-EOT
    Define tags on the context so they can be used on each resource.
    (For Example: `{'Owner': 'group-sre@test.com'}`)
    EOT
}

variable "context" {
  type = object({
    enabled        = optional(bool)
    group          = optional(string)
    tenant         = optional(string)
    env            = optional(string)
    scope          = optional(string)
    attributes     = optional(list(string))
    tags           = optional(map(string))
    tag_key_case   = optional(string)
    tag_value_case = optional(string)
  })
  default     = {}
  description = <<-EOT
    A context object from another instance of this module, usually its
    `context` output. Variables set on this module override its values, except
    attributes, which the module combines.
  EOT
  validation {
    condition = alltrue([
      for v in concat(
        [var.context.group, var.context.tenant, var.context.env, var.context.scope],
        coalesce(var.context.attributes, []),
      ) : v == null ? true : can(regex("^[0-9A-Za-z-]*$", v))
    ])
    error_message = "Context group, tenant, env, scope and attributes can only be alphanumeric and hyphens."
  }
}

variable "max_id_length" {
  type        = number
  default     = 255
  description = <<-EOT
    The maximum length of `id_truncated_hash`. When the ID is longer, the module
    truncates it and adds a hash suffix. For example, use 63 for S3 bucket names.
    Must be a whole number greater than 8.
    EOT
  validation {
    condition     = var.max_id_length > 8 && floor(var.max_id_length) == var.max_id_length
    error_message = "max_id_length must be a whole number greater than 8, the length of the hash suffix."
  }
}

variable "delimiter" {
  type        = string
  default     = "-"
  description = <<-EOT
    Delimiter to use between ID parts: 1 to 3 of the characters `-`, `_` and
    `.`. Defaults to a hyphen.
    EOT
  validation {
    condition     = can(regex("^[-_.]{1,3}$", var.delimiter))
    error_message = "Delimiter must be 1 to 3 of the characters -, _ and ."
  }
}

variable "tag_key_case" {
  type        = string
  default     = null
  nullable    = true
  description = <<-EOT
    The case for tag keys: lower, upper or title. Cloud provider tag keys are
    case-sensitive, so one case for all keys avoids duplicates. Defaults to
    "lower" when neither this variable nor the context sets it.
    EOT
  validation {
    condition     = var.tag_key_case == null ? true : contains(["lower", "upper", "title"], var.tag_key_case)
    error_message = "Value must be one of: lower, upper, title."
  }
}

variable "tag_value_case" {
  type        = string
  default     = "lower"
  nullable    = true
  description = <<-EOT
    The case for tag values: lower, upper or title. Set to null to keep the
    original case.
    EOT
  validation {
    condition     = var.tag_value_case == null ? true : contains(["lower", "upper", "title"], var.tag_value_case)
    error_message = "Value must be one of: lower, upper, title."
  }
}

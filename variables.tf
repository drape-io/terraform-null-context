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
    condition     = var.group == null || var.group == "" || can(regex("^[0-9|A-Z|a-z|-]+$", var.group))
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
    condition     = var.tenant == null || var.tenant == "" || can(regex("^[0-9|A-Z|a-z|-]+$", var.tenant))
    error_message = "Value can only be alphanumeric and hyphens."
  }
}

variable "env" {
  type        = string
  default     = null
  nullable    = true
  description = <<-EOT
    Should be the type of environment for the resource (prd, stg, dev, prf, sec)
  EOT
  validation {
    condition     = var.env == null || var.env == "" || can(regex("^[0-9|A-Z|a-z|-]+$", var.env))
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
    condition     = var.scope == null || var.scope == "" || can(regex("^[0-9|A-Z|a-z|-]+$", var.scope))
    error_message = "Value can only be alphanumeric and hyphens."
  }
}

variable "attributes" {
  type        = list(string)
  default     = []
  description = <<-EOT
    Additional attributes can be added to create more uniqueness when in the ID.
    They are appended to the end of the ID.
    EOT
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
    Used to pass an object of any of the variables used to this module.  It is
    used to seed the module with labels from another context.
  EOT
}

variable "max_id_length" {
  type        = number
  default     = 255
  description = <<-EOT
    This will define a max length we want for the generated ID and then generate
    a truncated one with a hash.  For example if you are generating S3 buckets
    you will want to limit it to 63 characters.
    EOT
}

variable "tag_key_case" {
  type        = string
  default     = "lower"
  description = <<-EOT
    Since cloud providers tags are not case-insensitive we should enforce a
    consistent casing for all keys.
    EOT
}

variable "tag_value_case" {
  type        = string
  default     = "lower"
  nullable    = true
  description = <<-EOT
    Since cloud providers tags are not case-insensitive we should enforce a
    consistent casing for all values.
    EOT
}

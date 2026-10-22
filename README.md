# terraform-null-context
A Terraform module that names and tags resources from a shared context.

[Terraform Registry](https://registry.terraform.io/modules/drape-io/context/null/latest)

## Basic Usage

From the Terraform Registry:

```hcl
module "context" {
  source  = "drape-io/context/null"
  version = "~> 1.0"

  group = "drape"
  env   = "prd"
  scope = "k8s"
}
```

From Git, pin the release tag in the source. Git sources do not support the
`version` argument.

```hcl
module "context" {
  source = "git::https://github.com/drape-io/terraform-null-context.git?ref=v1.0.0"

  group = "drape"
  env   = "prd"
  scope = "k8s"
}
```

The module joins the parts you give it into an ID and builds a matching set of
tags. Pass `module.context.context` to other modules so they share the same
naming.

## ID format

The parts are:

| Name       | Description                                                  |
|------------|--------------------------------------------------------------|
| group      | The primary identifier for your resources, such as your organization |
| tenant     | Identifies a tenant, or a developer in a sandbox             |
| env        | The environment for the resource (prd, stg, dev, prf, sbx, sec) |
| scope      | Application name or another scope for the resources          |
| attributes | List of extra values appended to the end of the ID           |

The module joins them in this order with the delimiter (`-` by default):

```
{group}-{tenant}-{env}-{scope}-{attributes}
```

Every part is optional, and the module skips empty parts. It also joins the
attributes with the delimiter. If you set no part, the ID is empty and
Terraform shows the failed check as a warning.

The module checks that `group`, `tenant`, `env`, `scope` and each attribute
contain only letters, digits and hyphens, both as variables and in `context`.
It does not check the ID length. It does not change the case of the ID.

For names that work across most AWS services, use this convention:

- Use only lowercase letters, digits and hyphens.
- Start with a letter. Do not end with a hyphen or use two hyphens in a row.
- Keep the ID between 3 and 63 characters. Set `max_id_length` and use the
  `id_truncated_hash` output when the full ID can be longer.

Examples:

- group and env:
    ```
    drape-prd
    ```

- All parts:
    ```
    drape-customer1-prd-authsvc-primary
    ```

## AWS Limits
This module is not specific to AWS. These AWS name limits guide the
convention:

- 63 (S3 bucket, RDS instance identifier)
  - s3: https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html
  - rds: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Limits.html#RDS_Limits.Constraints
- 64 (IAM role, Lambda function name)
  - lambda: https://docs.aws.amazon.com/lambda/latest/dg/API_CreateFunction.html#API_CreateFunction_RequestSyntax
- 255 (DynamoDB table), 256 (SNS topic)

## Environment
The `environment` tag expands these `env` shorthands. Other values are used as
they are.

- production = prd
- staging = stg
- development = dev
- performance = prf
- sandbox = sbx
- security = sec

## Region Names
The module does not handle regions. If you add a region to an ID (for example
as an attribute), use the short AZ ID form:
https://docs.aws.amazon.com/workspaces/latest/adminguide/azs-workspaces.html

- us-east-1 = use1
- eu-central-1 = euc1

## Truncated IDs
When the ID is longer than `max_id_length`, the `id_truncated_hash` output keeps
the start of the ID and adds the delimiter and a hash suffix. The suffix is the
start of the SHA-256 hash of the full ID, so the same ID always gets the same
suffix. The module trims a trailing delimiter from the kept part and makes the
suffix longer to fill the space.

## Tags
The `tags` output combines these sources. Later sources win when keys match
after key casing:

1. Tags inherited through `context`.
2. Tags generated from `group`, `tenant`, `env` (as `environment`) and `scope`, for the parts that are set.
3. The `tags` variable.
4. `managed-by = terraform`.

The module drops tags with an empty or null value.

## Slash IDs
Some resources, such as KMS aliases, need a slash-separated ID. The
`id_slash_full` output joins the same parts with `/`. Add any prefix, such as
`alias/`, yourself. Attributes stay in one segment, joined with the delimiter.

```
alias/drape/prd/lambda
        ^    ^    ^
     group  env  scope

alias/drape/sontek/dev/lambda
        ^     ^     ^    ^
     group tenant  env  scope
```

## More examples
```
-> drape-prd-k8s
     ^    ^    ^
   group env  scope

-> drape-sontek-dev-k8s
     ^     ^     ^    ^
   group tenant env  scope

-> drape-prd-k8s-primary-replica
     ^    ^    ^       ^
   group env  scope  attributes
```

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_attributes"></a> [attributes](#input\_attributes) | Extra values to append to the end of the ID to make it unique. | `list(string)` | `[]` | no |
| <a name="input_context"></a> [context](#input\_context) | A context object from another instance of this module, usually its<br>`context` output. Variables set on this module override its values, except<br>attributes, which the module combines. | <pre>object({<br>    enabled        = optional(bool)<br>    group          = optional(string)<br>    tenant         = optional(string)<br>    env            = optional(string)<br>    scope          = optional(string)<br>    attributes     = optional(list(string))<br>    tags           = optional(map(string))<br>    tag_key_case   = optional(string)<br>    tag_value_case = optional(string)<br>  })</pre> | `{}` | no |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | Delimiter to use between ID parts: 1 to 3 of the characters `-`, `_` and<br>`.`. Defaults to a hyphen. | `string` | `"-"` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Prevent the module from creating any resources if disabled. | `bool` | `null` | no |
| <a name="input_env"></a> [env](#input\_env) | Should be the type of environment for the resource (prd, stg, dev, prf, sbx, sec) | `string` | `null` | no |
| <a name="input_group"></a> [group](#input\_group) | A unique identifier for your resources.  This could be your organization<br>name or an abbreviation | `string` | `null` | no |
| <a name="input_max_id_length"></a> [max\_id\_length](#input\_max\_id\_length) | The maximum length of `id_truncated_hash`. When the ID is longer, the module<br>truncates it and adds a hash suffix. For example, use 63 for S3 bucket names.<br>Must be a whole number greater than 8. | `number` | `255` | no |
| <a name="input_scope"></a> [scope](#input\_scope) | Scope down the resource to a specific application or service in your<br>environment | `string` | `null` | no |
| <a name="input_tag_key_case"></a> [tag\_key\_case](#input\_tag\_key\_case) | The case for tag keys: lower, upper or title. Cloud provider tag keys are<br>case-sensitive, so one case for all keys avoids duplicates. Defaults to<br>"lower" when neither this variable nor the context sets it. | `string` | `null` | no |
| <a name="input_tag_value_case"></a> [tag\_value\_case](#input\_tag\_value\_case) | The case for tag values: lower, upper or title. Set to null to keep the<br>original case. | `string` | `"lower"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Define tags on the context so they can be used on each resource.<br>(For Example: `{'Owner': 'group-sre@test.com'}`) | `map(string)` | `null` | no |
| <a name="input_tenant"></a> [tenant](#input\_tenant) | In a multi-tenant environment you can use this to identify which resources<br>go where. You can also use this to link resources to individual developers<br>in sandboxes. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_context"></a> [context](#output\_context) | The context object to pass to another instance of this module |
| <a name="output_enabled"></a> [enabled](#output\_enabled) | Whether the module is enabled |
| <a name="output_group"></a> [group](#output\_group) | The defined group |
| <a name="output_id_full"></a> [id\_full](#output\_id\_full) | The full ID |
| <a name="output_id_slash_full"></a> [id\_slash\_full](#output\_id\_slash\_full) | The ID with `/` between the parts |
| <a name="output_id_truncated"></a> [id\_truncated](#output\_id\_truncated) | The part of the ID kept before the hash suffix: at most `max_id_length` minus 8 chars, without a trailing delimiter |
| <a name="output_id_truncated_hash"></a> [id\_truncated\_hash](#output\_id\_truncated\_hash) | The ID, truncated to `max_id_length` with a hash suffix when it is longer |
| <a name="output_tags"></a> [tags](#output\_tags) | The generated tags |
| <a name="output_tenant"></a> [tenant](#output\_tenant) | The defined tenant |
<!-- END_TF_DOCS -->

# terraform-null-context
A utility module for managing naming and tagging of resources through a shared
context.

[Terraform Registry](https://registry.terraform.io/modules/drape-io/context/null/latest)

## Basic Usage

```hcl
module "context" {
  source  = "drape-io/context/null"
  version = "~> 1.0"

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

Every part is optional and empty parts are skipped. If no part is set, the ID
is empty and Terraform reports a failed check as a warning. Attributes are
joined with the delimiter.

The module validates that `group`, `tenant`, `env` and `scope` contain only
letters, digits and hyphens when you pass them as variables. It does not
validate values passed through `context`, the `attributes` list, or the ID
length. It does not change the case of the ID.

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
This module is not specific to AWS, but these name limits help guide the
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
| <a name="input_attributes"></a> [attributes](#input\_attributes) | Additional attributes can be added to create more uniqueness when in the ID.<br>They are appended to the end of the ID. | `list(string)` | `[]` | no |
| <a name="input_context"></a> [context](#input\_context) | Used to pass an object of any of the variables used to this module.  It is<br>used to seed the module with labels from another context. | <pre>object({<br>    enabled        = optional(bool)<br>    group          = optional(string)<br>    tenant         = optional(string)<br>    env            = optional(string)<br>    scope          = optional(string)<br>    attributes     = optional(list(string))<br>    tags           = optional(map(string))<br>    tag_key_case   = optional(string)<br>    tag_value_case = optional(string)<br>  })</pre> | `{}` | no |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | Delimiter to use between ID parts.  Defaults to a hyphen. | `string` | `"-"` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Prevent the module from creating any resources if disabled. | `bool` | `null` | no |
| <a name="input_env"></a> [env](#input\_env) | Should be the type of environment for the resource (prd, stg, dev, prf, sbx, sec) | `string` | `null` | no |
| <a name="input_group"></a> [group](#input\_group) | A unique identifier for your resources.  This could be your organization<br>name or an abbreviation | `string` | `null` | no |
| <a name="input_max_id_length"></a> [max\_id\_length](#input\_max\_id\_length) | This will define a max length we want for the generated ID and then generate<br>a truncated one with a hash.  For example if you are generating S3 buckets<br>you will want to limit it to 63 characters. | `number` | `255` | no |
| <a name="input_scope"></a> [scope](#input\_scope) | Scope down the resource to a specific application or service in your<br>environment | `string` | `null` | no |
| <a name="input_tag_key_case"></a> [tag\_key\_case](#input\_tag\_key\_case) | Since cloud providers tags are not case-insensitive we should enforce a<br>consistent casing for all keys.  Defaults to "lower" when not set via<br>variable or context. | `string` | `null` | no |
| <a name="input_tag_value_case"></a> [tag\_value\_case](#input\_tag\_value\_case) | Since cloud providers tags are not case-insensitive we should enforce a<br>consistent casing for all values.  Set to null to preserve original casing. | `string` | `"lower"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Define tags on the context so they can be used on each resource.<br>(For Example: `{'Owner': 'group-sre@test.com'}`) | `map(string)` | `null` | no |
| <a name="input_tenant"></a> [tenant](#input\_tenant) | In a multi-tenant environment you can use this to identify which resources<br>go where. You can also use this to link resources to individual developers<br>in sandboxes. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_context"></a> [context](#output\_context) | The full context object if you want to pass it to another module |
| <a name="output_enabled"></a> [enabled](#output\_enabled) | If it was enabled or not |
| <a name="output_group"></a> [group](#output\_group) | The defined group |
| <a name="output_id_full"></a> [id\_full](#output\_id\_full) | The full ID |
| <a name="output_id_slash_full"></a> [id\_slash\_full](#output\_id\_slash\_full) | The full ID with slashes |
| <a name="output_id_truncated"></a> [id\_truncated](#output\_id\_truncated) | The full ID truncated to `max_id_length` minus 8 chars, leaving room for the hash suffix |
| <a name="output_id_truncated_hash"></a> [id\_truncated\_hash](#output\_id\_truncated\_hash) | The full ID truncated with a hash |
| <a name="output_tags"></a> [tags](#output\_tags) | Tags for the context |
| <a name="output_tenant"></a> [tenant](#output\_tenant) | The defined tenant |
<!-- END_TF_DOCS -->

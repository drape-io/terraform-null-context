# terraform-null-context
A utility module for managing naming and tagging of resources through a shared
context.

[Terraform Registry](https://registry.terraform.io/modules/drape-io/context/null/latest)

## Basic Usage

```hcl
module "context" {
  source  = "drape-io/context/null"
  version = "0.0.10"
}
```

This utility will allow you to generate unique resources and enforce a standard
naming convention across your resources.  The convention will be:

- Only lowercase alphanumeric characters and hyphens.
- First character must be a letter, cannot end with a hyphen or contain two
 consecutive hyphens.
- Minimum of 3 characters and maximum of 63.

The fields available are:
|Name                | Description                                              |
|--------------------|----------------------------------------------------------|
| group              | The prefix our primary unique identifier for the assets  |
| tenant             | If you need to identify a tenant for the resource        |
| env                | The environment for the resource (prd, stg, dev, prf)    |
| scope              | Application name or some other unique scope for resources|
| attributes         | List of additional attributes to uniquely identify the resources  |

With the following format:

```
{group}-{[tenant]}-{env}-{[region]}-{[scope]}-{[attributes]}-{name}
```

Real world examples:

- group, env, name:
    ```
    drape-prd-primary-rds
    ```

- All fields
    ```
    drape-customer1-prd-use1-authsvc-primary-rds
    ```

## AWS Limits
This module is not AWS specific but this helps guide a good naming convention:

- 140 (Lambda)
  - https://docs.aws.amazon.com/lambda/latest/dg/API_CreateFunction.html#API_CreateFunction_RequestSyntax
- 63 (RDS, S3, IAM Role)
  - s3: https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html
  - rds: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Limits.html#RDS_Limits.Constraints
- 255 (sns topic, dynamo table) 

# Environment
- production = prd
- staging = stg
- development = dev
- performance = prf
- security = sec

# Region Replacement
Use supported AZ IDs.
https://docs.aws.amazon.com/workspaces/latest/adminguide/azs-workspaces.html

- us-east-1 = use1
- eu-central-1 = euc1

# KMS Alias
Sometimes you need a slash based id as well.  We support this through the
output `id_slash_full`.

```
alias/drape/prod/lambda
alias/drape/dev/sontek/lambda
        ^    ^     ^       ^
      prefix env  tenant  name
```

# Examples
```
-> drape-prod-eu-central-1-k8s-grafana-pg-backup
     ^     ^     ^          ^          ^
   group  env  region    scope     name

-> drape-sontek-dev-us-east-1-k8s-grafana-pg-backup
     ^     ^     ^        ^     ^          ^
   group tenant env    region  scope      name

-> drape-prod-k8s-ingress-a
     ^    ^     ^       ^
   group env  scope    name
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_attributes"></a> [attributes](#input\_attributes) | Additional attributes can be added to create more uniqueness when in the ID.<br>They are appended to the end of the ID. | `list(string)` | `[]` | no |
| <a name="input_context"></a> [context](#input\_context) | Used to pass an object of any of the variables used to this module.  It is<br>used to seed the module with labels from another context. | <pre>object({<br>    enabled        = optional(bool)<br>    group          = optional(string)<br>    tenant         = optional(string)<br>    env            = optional(string)<br>    scope          = optional(string)<br>    attributes     = optional(list(string))<br>    tags           = optional(map(string))<br>    tag_key_case   = optional(string)<br>    tag_value_case = optional(string)<br>  })</pre> | `{}` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Prevent the module from creating any resources if disabled. | `bool` | `null` | no |
| <a name="input_env"></a> [env](#input\_env) | Should be the type of environment for the resource (prd, stg, dev, prf, sec) | `string` | `null` | no |
| <a name="input_group"></a> [group](#input\_group) | A unique identifier for your resources.  This could be your organization<br>name or an abbreviation | `string` | `null` | no |
| <a name="input_max_id_length"></a> [max\_id\_length](#input\_max\_id\_length) | This will define a max length we want for the generated ID and then generate<br>a truncated one with a hash.  For example if you are generating S3 buckets<br>you will want to limit it to 63 characters. | `number` | `255` | no |
| <a name="input_scope"></a> [scope](#input\_scope) | Scope down the resource to a specific application or service in your<br>environment | `string` | `null` | no |
| <a name="input_tag_key_case"></a> [tag\_key\_case](#input\_tag\_key\_case) | Since cloud providers tags are not case-insensitive we should enforce a<br>consistent casing for all keys. | `string` | `"lower"` | no |
| <a name="input_tag_value_case"></a> [tag\_value\_case](#input\_tag\_value\_case) | Since cloud providers tags are not case-insensitive we should enforce a<br>consistent casing for all values. | `string` | `"lower"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Define tags on the context so they can be used on each resource.<br>(For Example: `{'Owner': 'group-sre@test.com'}`) | `map(string)` | `{}` | no |
| <a name="input_tenant"></a> [tenant](#input\_tenant) | In a multi-tenant environment you can use this to identify which resources<br>go where. You can also use this to link resources to individual developers<br>in sandboxes. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_context"></a> [context](#output\_context) | The full context object if you want to pass it to another module |
| <a name="output_enabled"></a> [enabled](#output\_enabled) | If it was enabled or not |
| <a name="output_group"></a> [group](#output\_group) | The defined group |
| <a name="output_id_full"></a> [id\_full](#output\_id\_full) | The full ID |
| <a name="output_id_slash_full"></a> [id\_slash\_full](#output\_id\_slash\_full) | The full ID with slashes |
| <a name="output_id_truncated"></a> [id\_truncated](#output\_id\_truncated) | The full ID truncated to `max_id_length` chars, leaving 8 for a hash |
| <a name="output_id_truncated_hash"></a> [id\_truncated\_hash](#output\_id\_truncated\_hash) | The full ID truncated with a hash |
| <a name="output_tags"></a> [tags](#output\_tags) | Tags for the context |
| <a name="output_tenant"></a> [tenant](#output\_tenant) | The defined tenant |

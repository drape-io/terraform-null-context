# terraform-null-context
A utility module for managing naming and tagging of resources through a shared
context.

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

- Only required fields (group, env, name):
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
production = prd
staging = stg
development = dev
performance = prf
security = sec

# Region Replacement
Use supported AZ IDs.
https://docs.aws.amazon.com/workspaces/latest/adminguide/azs-workspaces.html

us-east-1 = use1
eu-central-1 = euc1

# TODO:
need to support kms alias as well...

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
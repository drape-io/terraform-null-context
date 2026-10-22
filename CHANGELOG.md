# Changelog

## 1.0.0

### Breaking changes

- `id_truncated_hash` uses a deterministic, lowercase hash suffix: the start
  of `sha256(id_full)`. Before, the suffix was a random string that could
  contain uppercase letters, which S3 rejects. Every ID that is longer than
  `max_id_length` gets a new name. Resources named from `id_truncated_hash`
  are renamed or replaced. IDs that fit in `max_id_length` do not change.
- When truncation cuts the ID right after a delimiter, the module trims that
  delimiter and makes the hash longer. `id_truncated` and `id_truncated_hash`
  no longer contain a doubled delimiter such as `abc--1a2b3c4`.
- The module no longer uses the `hashicorp/random` provider. A module that
  truncated its ID has `random_string.hash_for_id[0]` in state. The next plan
  destroys it. This only removes local state and changes no cloud resource.
  Modules whose ID was not truncated have no such resource in state.
- New validation rejects inputs that were accepted before:
  - `max_id_length` must be a whole number greater than 8. Smaller values
    produced IDs longer than the limit or IDs that started with the delimiter.
  - `delimiter` must be 1 to 3 of the characters `-`, `_` and `.`.
  - `attributes`, and the `group`, `tenant`, `env`, `scope` and `attributes`
    fields of `context`, can only contain letters, digits and hyphens. Before,
    only the top-level variables were checked.
- Tag changes for modules that receive a `context`:
  - Tags generated from this module's own parts now win over tags inherited
    through `context`. Before, a child that set `env = "prd"` kept the
    parent's `environment` tag.
  - The `tags` variable now adds to the tags inherited through `context`.
    Before, it replaced all of them.

### Fixes

- A child module no longer fails with `Duplicate object key` when its parent
  uses `tag_key_case = "upper"` or `"title"`, or when a tag key differs from a
  generated key only in case (for example `Environment`).
- Tags with a null value are dropped instead of failing.
- The `env` shorthand expands in any case: `PRD` gives `environment =
  production`.
- The README describes what the module validates, the tag precedence, and how
  to pin a Git source with `?ref=`.

IDs, slash IDs and tags for inputs that do not truncate and do not inherit
tags through `context` are unchanged.

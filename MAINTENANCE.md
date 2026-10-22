# Releasing a new version

1. Regenerate the inputs and outputs tables in the README:

   ```
   terraform-docs markdown table --show inputs,outputs --output-file README.md --output-mode inject .
   ```

2. Add a section for the version to `CHANGELOG.md`. List breaking changes
   first.

3. After the changes merge to `main`, create the release and its tag from the
   changelog section:

   ```
   gh release create v1.0.0 --target main --title v1.0.0 --notes-file notes.md
   ```

Releases are immutable. Do not move or delete a published tag. Fix a bad
release with a new version.

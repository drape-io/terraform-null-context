# Releasing a new version

1. Regenerate the inputs and outputs tables in the README:

   ```
   terraform-docs markdown table --show inputs,outputs --output-file README.md --output-mode inject .
   ```

2. Tag the release and push the tag:

   ```
   git tag -a v1.0.0 -m "Release v1.0.0"
   git push origin v1.0.0
   ```

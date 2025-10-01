# CloudKit Private Database Verification

This repository does not include credentials for Bonfire's CloudKit containers, so the steps below outline how to verify the private database schema locally. Follow these instructions from a macOS environment that has access to the Bonfire CloudKit container.

## Prerequisites
- Xcode command-line tools installed.
- The CloudKit CLI (`cktool`) available in your `$PATH`.
- Access to the `iCloud.com.bonefire.myapp` container with the Public schema already imported.

## Steps
1. **Authenticate to CloudKit**  
   ```sh
   cktool auth login
   ```
   Select the appropriate Apple ID that has access to the container when prompted.
2. **Import the private database schema**  
   Run the import command from the repository root:
   ```sh
   cktool schema import --path Bonfire/Cloud/Schema/PrivateDatabaseSchema.json --environment development --database private
   ```
3. **Verify the schema in CloudKit Dashboard**  
   - Open [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard/).
   - Switch to the `iCloud.com.bonefire.myapp` container and choose the *Development* environment.
   - Navigate to the *Private Database* and inspect each record type.
   - Confirm that record fields and indexes match the definitions in `Bonfire/Cloud/Schema/PrivateDatabaseSchema.json`.

If any discrepancies appear, re-run the import command or adjust the schema JSON file before retrying.

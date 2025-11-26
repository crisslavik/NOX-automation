# Nuke Installation Files

Place Foundry Nuke installer files in this directory.

## Required Files

Download the Nuke Linux installer from Foundry and place it here with this naming format:

- `Nuke<version>v<patch>-linux-x86_64.run`

### Examples:
- `Nuke16.0v6-linux-x86_64.run`
- `Nuke15.2v3-linux-x86_64.run`
- `Nuke14.1v5-linux-x86_64.run`

## Download Location

Get Nuke installers from:
https://www.foundry.com/products/nuke/download

(Requires Foundry account)

## Version Configuration

The Nuke version is configured in your playbook or group_vars:

```yaml
nuke_version: "16.0"   # Major.Minor version
nuke_patch: "6"        # Patch version
```

This generates the installer filename: `Nuke16.0v6-linux-x86_64.run`

## Usage

The Ansible playbook will automatically:
1. Look for the installer in Files/nuke/ or Files/ directory
2. Copy it to the target machine at /tmp/
3. Run the installer with proper permissions
4. Configure environment variables (foundry_LICENSE, NUKE_PATH)
5. Clean up temporary files

## License Configuration

The Nuke license server is configured in `group_vars/all.yml`:
```yaml
foundry_license: "5053@license"
```

This is automatically set as the `foundry_LICENSE` environment variable.

# Das Element Lite Installation Files

Place Das Element Lite RPM installer in this directory.

## Required Files

Download the Das Element Lite RPM installer and place it here with the filename:

- `das-element-lite.rpm`

## Download Location

Get Das Element from:
https://www.daselement.com/download

(Requires Das Element account)

## Version Configuration

The installer filename is configured in the role defaults:

```yaml
daselement_installer_filename: "das-element-lite.rpm"
```

You can override this in your playbook or group_vars if using a different version.

## Usage

The Ansible playbook will automatically:
1. Check if Das Element is already installed
2. Install libXScrnSaver dependency
3. Copy the RPM from Files/das-element/ to the target machine
4. Install Das Element Lite using DNF
5. Configure environment variables (license, config path, resources)
6. Create wrapper scripts for proper environment setup
7. Update desktop launchers
8. Apply configuration to existing users
9. Clean up temporary files

## Environment Configuration

The role configures these environment variables:
```bash
DASELEMENT_LICENSE=<license_server>
DASELEMENT_CONFIG_PATH=/mnt/Library/_daselement/das-element.conf
DASELEMENT_RESOURCES=/mnt/Library/_daselement/resources
```

Configure these in `group_vars/all.yml`:
```yaml
das_element_license: "port@server"
```

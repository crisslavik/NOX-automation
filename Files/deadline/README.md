# AWS Thinkbox Deadline Client Installation Files

Place Deadline Client installer files in this directory.

## Required Files

Download the Deadline Client Linux installer from AWS and place it here:

- `DeadlineClient-10.3-linux-x64-installer.run`

Or whatever version you're using (update the variable accordingly).

## Download Location

Get Deadline Client from:
https://www.awsthinkbox.com/deadline

(Requires AWS Thinkbox account)

## Version Configuration

The installer filename is configured in the role defaults:

```yaml
deadline_installer_filename: "DeadlineClient-10.3-linux-x64-installer.run"
deadline_install_dir: "/opt/Thinkbox/Deadline10"
```

You can override these in your playbook or group_vars for different versions.

## Usage

The Ansible playbook will automatically:
1. Check if Deadline client is already installed
2. Copy the installer from Files/deadline/ to the target machine
3. Run the installer in unattended mode
4. Install to /opt/Thinkbox/Deadline10
5. Clean up temporary installer file
6. Configure Deadline repository connection (if configured)

## Repository Configuration

After installation, you may need to configure the Deadline repository connection.
This is typically done by running:

```bash
/opt/Thinkbox/Deadline10/bin/deadlinecommand SetIniFileSetting ConnectionType Repository
/opt/Thinkbox/Deadline10/bin/deadlinecommand SetIniFileSetting ProxyUseSSL False
/opt/Thinkbox/Deadline10/bin/deadlinecommand SetIniFileSetting ProxyRoot "/mnt/deadline/repository"
```

You can add repository configuration tasks to the role if needed.

## Integration with DCC Software

Deadline integrates with:
- Blender (configured in blender role)
- Nuke
- Maya
- 3ds Max
- Other DCC applications

The Blender role automatically configures the Deadline plugin path.

# NOX VFX Site-Basic Playbook Usage Guide

## Overview

`site-basic.yml` is your **one-command** starter playbook that sets up the complete foundation for a NOX VFX workstation.

## What It Does

This playbook orchestrates 9 essential setup phases:

1. **System Updates** - Full system package updates
2. **Active Directory Integration** - Domain join and authentication
3. **GNOME Desktop** - Dark theme & VFX optimizations
4. **Local Package Cache** - Faster package installations
5. **NVIDIA Drivers** - Official GPU drivers
6. **NOX Branding** - Company wallpaper
7. **Wake-on-LAN** - Remote power management
8. **Nice DCV** - Remote desktop access
9. **Essential Apps** - Chrome & Sublime Text

## Quick Start

### Basic Usage

```bash
# Run full basic setup
ansible-playbook -i inventory playbooks/site-basic.yml

# Run with password prompt (for AD join)
ansible-playbook -i inventory playbooks/site-basic.yml --ask-pass

# Run on specific host
ansible-playbook -i inventory playbooks/site-basic.yml --limit workstation-01
```

### Skip Specific Phases

```bash
# Skip system updates
ansible-playbook -i inventory playbooks/site-basic.yml -e "skip_updates=true"

# Skip domain join (for testing)
ansible-playbook -i inventory playbooks/site-basic.yml -e "skip_domain_join=true"

# Skip automatic reboot
ansible-playbook -i inventory playbooks/site-basic.yml -e "skip_reboot=true"
```

### Run Only Specific Phases

```bash
# Only GNOME configuration (Phase 3)
ansible-playbook -i inventory playbooks/site-basic.yml --tags phase3

# Only NVIDIA drivers (Phase 5)
ansible-playbook -i inventory playbooks/site-basic.yml --tags phase5

# Only applications (Phase 9)
ansible-playbook -i inventory playbooks/site-basic.yml --tags phase9

# Multiple phases
ansible-playbook -i inventory playbooks/site-basic.yml --tags phase3,phase5,phase9
```

### Tag Categories

Available tags:

- **Phase tags**: `phase1`, `phase2`, `phase3`, ... `phase9`
- **Component tags**:
  - `updates` - System updates
  - `domain`, `authentication` - AD integration
  - `desktop`, `gnome` - Desktop environment
  - `cache`, `packages` - Package cache
  - `nvidia`, `drivers`, `gpu` - NVIDIA setup
  - `branding`, `wallpaper` - Company branding
  - `network`, `wol` - Network config
  - `remote`, `dcv` - Remote desktop
  - `applications`, `chrome`, `sublime` - Apps

## Typical Workflows

### 1. Fresh Workstation Setup

```bash
# Full setup (recommended)
ansible-playbook -i inventory playbooks/site-basic.yml

# This will:
# - Update all packages
# - Join AD domain (will prompt for password)
# - Configure GNOME with dark theme
# - Install NVIDIA drivers
# - Set up remote access
# - Install essential apps
# - Reboot when done
```

### 2. Update Existing Workstation

```bash
# Skip domain join, just update everything else
ansible-playbook -i inventory playbooks/site-basic.yml -e "skip_domain_join=true"
```

### 3. Quick Desktop Refresh

```bash
# Just update GNOME settings and apps
ansible-playbook -i inventory playbooks/site-basic.yml --tags desktop,applications
```

### 4. NVIDIA Driver Update

```bash
# Only update NVIDIA drivers
ansible-playbook -i inventory playbooks/site-basic.yml --tags nvidia
```

## Execution Time

Typical execution times (depends on network and hardware):

- **Full setup**: 15-25 minutes
- **Without updates**: 10-15 minutes
- **Single phase**: 2-5 minutes

## What Happens After Completion

After successful completion:

1. **Completion marker created**: `/etc/nox-setup-complete.txt`
2. **System may auto-reboot** (if kernel updated)
3. **AD login enabled** - Log in with domain credentials
4. **Desktop configured** - Dark theme, extensions enabled
5. **Remote access ready** - DCV server running

## Verification

After completion, verify:

```bash
# Check setup completion marker
cat /etc/nox-setup-complete.txt

# Verify NVIDIA drivers
nvidia-smi

# Check domain join status
realm list

# Verify GNOME config (as user)
/usr/local/bin/verify-nox-gnome.sh

# Check DCV status
sudo systemctl status dcvserver
```

## Troubleshooting

### Domain Join Fails

```bash
# Check network connectivity to domain controller
ping dc-1.ad.noxvfx.com

# Check if already joined
realm list

# Re-run only domain join
ansible-playbook -i inventory playbooks/site-basic.yml --tags domain
```

### NVIDIA Drivers Not Loading

```bash
# Check if nouveau (open-source) is still active
lsmod | grep nouveau

# If so, reboot is required
sudo reboot

# After reboot, verify
nvidia-smi
```

### GNOME Dark Theme Not Applied

```bash
# Run verification as user
/usr/local/bin/verify-nox-gnome.sh

# Force reconfiguration
/usr/local/bin/set-nox-gnome-config.sh --force

# Log out and back in
```

## Next Steps After Basic Setup

Once `site-basic.yml` completes, you can install additional VFX software:

```bash
# Install Nuke 15
ansible-playbook -i inventory playbooks/softwares/nuke15.yml

# Install Blender
ansible-playbook -i inventory playbooks/softwares/blender.yml

# Install DaVinci Resolve
ansible-playbook -i inventory playbooks/softwares/Davinci20.yml

# Install DasElement (for supervisors)
ansible-playbook -i inventory playbooks/softwares/das-element.yml

# Or use the full site.yml for everything
ansible-playbook -i inventory playbooks/site.yml
```

## Comparison: site-basic.yml vs site.yml

| Playbook | Purpose | Software Included | Time |
|----------|---------|-------------------|------|
| **site-basic.yml** | Foundation setup | Essential only (Chrome, Sublime) | 15-25 min |
| **site.yml** | Complete VFX workstation | All VFX software (Nuke, Blender, DaVinci, etc.) | 45-90 min |

**Recommendation**:
- Use `site-basic.yml` first to get the system running
- Test and verify basic functionality
- Then install specific VFX software as needed

## Advanced Usage

### Dry Run (Check Mode)

```bash
# See what would be changed without making changes
ansible-playbook -i inventory playbooks/site-basic.yml --check
```

### Verbose Output

```bash
# See detailed execution
ansible-playbook -i inventory playbooks/site-basic.yml -v

# Maximum verbosity
ansible-playbook -i inventory playbooks/site-basic.yml -vvv
```

### Run on Multiple Hosts

```bash
# Set up entire lab
ansible-playbook -i inventory playbooks/site-basic.yml --limit workstations

# Parallel execution (10 hosts at once)
ansible-playbook -i inventory playbooks/site-basic.yml --forks 10
```

## Files Created

After successful run:

- `/etc/nox-setup-complete.txt` - Completion marker with details
- `/usr/local/bin/set-nox-gnome-config.sh` - GNOME config script
- `/usr/local/bin/verify-nox-gnome.sh` - GNOME verification script
- `/etc/profile.d/neatvideo.sh` - Software environment variables
- `/etc/dcv/dcv.conf.d/gnome-optimization.conf` - DCV optimizations

## Support

For issues or questions:

1. Check logs: `/tmp/nox-gnome-config-USERNAME.log`
2. Review completion marker: `/etc/nox-setup-complete.txt`
3. Consult: [FINAL_REORGANIZATION_GUIDE.md](FINAL_REORGANIZATION_GUIDE.md)
4. See improvements: [IMPROVEMENT_RECOMMENDATIONS.md](IMPROVEMENT_RECOMMENDATIONS.md)

---

**Created**: 2025-11-20
**Playbook**: site-basic.yml
**Version**: 1.0

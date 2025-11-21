# nice-dcv role

This role installs and configures NICE DCV server components.

Important notes:
- This repository follows the 'installers on target' policy: proprietary RPMs are not stored here.
- Place DCV RPMs on the target host under `{{ nice_dcv_packages_dir }}` (default `/tmp/nice-dcv-packages`) before running this role, or set `nice_dcv_packages_dir` to your path.
- The DCV license server string is configured via `nice_dcv_rlm_license` (default in `defaults/main.yml`). Store the real value in Ansible Vault and override per environment.

Key variables (defaults in `defaults/main.yml`):
- `nice_dcv_packages_dir` - path on target host where RPMs are expected.
- `nice_dcv_expected_rpms` - list of expected RPM filenames (informational).
- `nice_dcv_rlm_license` - string for RLM license server (use Vault in production).

Usage:

ansible-playbook -i inventory playbooks/softwares/niceDCV.yml

Domain join role

This role joins AlmaLinux machines to Active Directory via realmd and configures SSSD, PAM helpers and NFS mounts.

Usage:
- Provide `domain_admin_password` via `--extra-vars` or Ansible Vault.

Example:
ansible-playbook -i inventory playbooks/site.yml -e "domain_admin_password='pa$$' update_system=false"

Notes:
- Designed for AlmaLinux 9.6
- The role will not reboot unless a kernel update occurs or the domain join command changed the system and requests a reboot.

cd NOX-automation/

# Make scripts executable (optional)
chmod +x *.sh

# Spread SSH keys to managed hosts
./deploy_ssh_keys.sh

# NOTE: Installer blobs (proprietary RPMs/.run/.zip) are no longer stored in this repo.
# Per the chosen policy (Option B) place proprietary installers on the target hosts
# under /tmp or use package managers/flatpak where possible. Role variables control
# the expected paths (see playbooks/roles/*/defaults/main.yml).

# Generate Ansible inventory (if needed)
./update-rpm-inventory.sh

# Run the site playbook (role-based)
ansible-playbook -i inventory playbooks/site.yml

# For per-role operations you can still run individual role wrappers:
ansible-playbook -i inventory playbooks/softwares/niceDCV.yml

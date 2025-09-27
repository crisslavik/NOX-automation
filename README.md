cd NOX-automation/

# Make scripts executable
chmod +x *.sh

# SPREAD THE SSH KEYS
./deploy_ssh_keys.sh

# Download RPMs (creates files/rpms/ structure)
./download-rpms.sh

# Check RPM integrity  
./verify-rpms.sh

# Generate Ansible inventory
./update-rpm-inventory.sh

# Deploy software
ansible-playbook playbooks/software/install-all-software.yml

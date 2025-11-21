# NOX-automation Strategic Upgrades & Template System

## 🎯 Overview

This document outlines strategic upgrades to transform your NOX-automation into a world-class, template-based deployment system.

---

## 🚀 Phase 1: Template-Based Deployment System

### Concept: Machine Profiles

Instead of running individual playbooks, create **machine profiles** that define what each type of machine needs.

### Proposed Structure:

```
playbooks/
├── profiles/                          # ⭐ NEW: Machine profiles
│   ├── workstation-artist.yml         # Artist workstation template
│   ├── workstation-supervisor.yml     # Supervisor workstation template
│   ├── render-node.yml                # Render farm node template
│   ├── server-deadline.yml            # Deadline server template
│   └── server-storage.yml             # Storage server template
├── group_vars/
│   ├── all.yml                        # Global config (already created)
│   ├── workstations.yml               # Workstation-specific vars
│   ├── render_nodes.yml               # Render node-specific vars
│   └── servers.yml                    # Server-specific vars
└── host_vars/                         # ⭐ NEW: Per-machine overrides
    ├── artist-ws-01.yml
    ├── artist-ws-02.yml
    └── render-01.yml
```

### Example Profile: Artist Workstation

**File:** `playbooks/profiles/workstation-artist.yml`

```yaml
---
- name: Deploy Artist Workstation
  hosts: workstations:&artists
  become: yes
  
  roles:
    # System Foundation
    - nox_system                    # Firewall, SELinux
    - domain_join                   # AD integration
    - gnome                         # Desktop environment
    
    # Creative Software
    - nuke                          # Compositing
    - davinci                       # Color grading
    - blender                       # 3D
    - krita                         # 2D painting
    - pureref                       # Reference images
    
    # Utilities
    - flameshot                     # Screenshots
    - slack                         # Communication
    - chrome                        # Browser
    
    # Render Integration
    - deadline-client               # Render farm client
    
    # Remote Access
    - nice-dcv                      # Remote desktop

  vars:
    # Profile-specific overrides
    nuke_versions:
      - "15.2"
      - "16.0"
    install_dev_tools: false
```

### Example Profile: Supervisor Workstation

**File:** `playbooks/profiles/workstation-supervisor.yml`

```yaml
---
- name: Deploy Supervisor Workstation
  hosts: workstations:&supervisors
  become: yes
  
  roles:
    # System Foundation
    - nox_system
    - domain_join
    - gnome
    
    # Creative Software (Full Suite)
    - nuke
    - davinci
    - blender
    - rv                            # Review tool
    - das-element                   # Asset management (full)
    
    # Development Tools
    - dev-util                      # Git, compilers, etc.
    - vscode                        # Code editor
    - sublime                       # Text editor
    
    # Utilities
    - flameshot
    - slack
    - chrome
    - brave
    
    # Render Integration
    - deadline-client
    
    # Remote Access
    - nice-dcv

  vars:
    nuke_versions:
      - "15.2"
      - "16.0"
    install_dev_tools: true
    das_element_type: "full"        # vs "lite"
```

### Example Profile: Render Node

**File:** `playbooks/profiles/render-node.yml`

```yaml
---
- name: Deploy Render Node
  hosts: render_nodes
  become: yes
  
  roles:
    # System Foundation
    - nox_system
    - domain_join
    
    # Render Software (headless)
    - nuke
    - blender
    - davinci
    
    # Render Farm
    - deadline-client
    
    # Plugins
    - neatvideo

  vars:
    # Render node optimizations
    install_gui: false
    nuke_versions:
      - "15.2"
      - "16.0"
    deadline_mode: "slave"
```

---

## 🎨 Phase 2: Inventory-Based Deployment

### Create Smart Inventory

**File:** `inventory/production.yml`

```yaml
---
all:
  children:
    workstations:
      children:
        artists:
          hosts:
            artist-ws-01:
              ansible_host: 192.168.1.101
            artist-ws-02:
              ansible_host: 192.168.1.102
            artist-ws-03:
              ansible_host: 192.168.1.103
        
        supervisors:
          hosts:
            super-ws-01:
              ansible_host: 192.168.1.201
            super-ws-02:
              ansible_host: 192.168.1.202
    
    render_nodes:
      hosts:
        render-[01:20]:
          ansible_host: 192.168.2.[1:20]
    
    servers:
      children:
        deadline_servers:
          hosts:
            deadline-01:
              ansible_host: 192.168.3.10
        
        storage_servers:
          hosts:
            storage-01:
              ansible_host: 192.168.3.20

  vars:
    ansible_user: ansible
    ansible_become: yes
```

### Deploy by Profile

```bash
# Deploy all artist workstations
ansible-playbook -i inventory/production.yml playbooks/profiles/workstation-artist.yml

# Deploy all supervisor workstations
ansible-playbook -i inventory/production.yml playbooks/profiles/workstation-supervisor.yml

# Deploy all render nodes
ansible-playbook -i inventory/production.yml playbooks/profiles/render-node.yml

# Deploy specific machine
ansible-playbook -i inventory/production.yml playbooks/profiles/workstation-artist.yml --limit artist-ws-01
```

---

## 🔧 Phase 3: Advanced Features

### 1. Machine Provisioning Playbook

**File:** `playbooks/provision-new-machine.yml`

```yaml
---
- name: Provision New Machine
  hosts: "{{ target_host }}"
  become: yes
  
  vars_prompt:
    - name: machine_profile
      prompt: "Select profile (artist/supervisor/render/server)"
      private: no
    
    - name: machine_name
      prompt: "Machine hostname"
      private: no
  
  tasks:
    - name: Set hostname
      ansible.builtin.hostname:
        name: "{{ machine_name }}"
    
    - name: Update /etc/hosts
      ansible.builtin.lineinfile:
        path: /etc/hosts
        line: "127.0.0.1 {{ machine_name }}"
        regexp: '^127\.0\.0\.1'
    
    - name: Apply machine profile
      ansible.builtin.include_role:
        name: "{{ item }}"
      loop: "{{ profiles[machine_profile] }}"
```

### 2. Software Update Playbook

**File:** `playbooks/update-software.yml`

```yaml
---
- name: Update Specific Software
  hosts: "{{ target_hosts | default('all') }}"
  become: yes
  
  vars_prompt:
    - name: software_name
      prompt: "Software to update (nuke/davinci/blender/all)"
      private: no
  
  tasks:
    - name: Update software
      ansible.builtin.include_role:
        name: "{{ software_name }}"
      when: software_name != 'all'
    
    - name: Update all software
      ansible.builtin.include_role:
        name: "{{ item }}"
      loop:
        - nuke
        - davinci
        - blender
        - deadline-client
      when: software_name == 'all'
```

### 3. Health Check Playbook

**File:** `playbooks/health-check.yml`

```yaml
---
- name: System Health Check
  hosts: all
  become: yes
  gather_facts: yes
  
  tasks:
    - name: Check firewall status
      ansible.builtin.systemd:
        name: firewalld
        state: started
      check_mode: yes
      register: firewall_check
    
    - name: Check SSSD status
      ansible.builtin.systemd:
        name: sssd
        state: started
      check_mode: yes
      register: sssd_check
    
    - name: Check license servers
      ansible.builtin.shell: |
        nc -zv {{ item.value.split(':')[0] }} {{ item.value.split(':')[1] | default('5053') }}
      loop: "{{ license_servers | dict2items }}"
      register: license_check
      failed_when: false
    
    - name: Check disk space
      ansible.builtin.shell: df -h / | tail -1 | awk '{print $5}' | sed 's/%//'
      register: disk_usage
    
    - name: Generate health report
      ansible.builtin.debug:
        msg: |
          === Health Check Report ===
          Hostname: {{ ansible_hostname }}
          Firewall: {{ 'OK' if firewall_check.changed == false else 'ISSUE' }}
          SSSD: {{ 'OK' if sssd_check.changed == false else 'ISSUE' }}
          Disk Usage: {{ disk_usage.stdout }}%
          License Servers: {{ license_check.results | selectattr('rc', 'equalto', 0) | list | length }}/{{ license_servers | length }} reachable
```

---

## 📊 Phase 4: Monitoring & Reporting

### 1. Deployment Dashboard

**File:** `playbooks/generate-dashboard.yml`

```yaml
---
- name: Generate Deployment Dashboard
  hosts: localhost
  gather_facts: no
  
  tasks:
    - name: Gather facts from all hosts
      ansible.builtin.setup:
      delegate_to: "{{ item }}"
      delegate_facts: yes
      loop: "{{ groups['all'] }}"
    
    - name: Generate HTML dashboard
      ansible.builtin.template:
        src: templates/dashboard.html.j2
        dest: /var/www/html/nox-dashboard.html
```

### 2. Software Inventory Report

**File:** `playbooks/software-inventory.yml`

```yaml
---
- name: Generate Software Inventory
  hosts: all
  become: yes
  
  tasks:
    - name: Check installed software
      ansible.builtin.shell: |
        echo "Nuke: $(ls /opt/Nuke* 2>/dev/null | wc -l) versions"
        echo "Blender: $(which blender &>/dev/null && echo 'Installed' || echo 'Not installed')"
        echo "DaVinci: $(ls /opt/resolve 2>/dev/null && echo 'Installed' || echo 'Not installed')"
      register: software_check
    
    - name: Generate report
      ansible.builtin.copy:
        content: |
          Software Inventory Report
          Generated: {{ ansible_date_time.iso8601 }}
          
          {% for host in groups['all'] %}
          {{ host }}:
          {{ hostvars[host].software_check.stdout }}
          {% endfor %}
        dest: /tmp/software-inventory-{{ ansible_date_time.date }}.txt
      delegate_to: localhost
      run_once: yes
```

---

## 🎯 Phase 5: CI/CD Integration

### GitLab CI Pipeline

**File:** `.gitlab-ci.yml`

```yaml
stages:
  - validate
  - test
  - deploy

validate:
  stage: validate
  script:
    - ansible-playbook --syntax-check playbooks/**/*.yml
    - ansible-lint playbooks/

test:
  stage: test
  script:
    - ansible-playbook -i inventory/test.yml playbooks/profiles/workstation-artist.yml --check

deploy-dev:
  stage: deploy
  script:
    - ansible-playbook -i inventory/dev.yml playbooks/profiles/workstation-artist.yml
  only:
    - develop

deploy-prod:
  stage: deploy
  script:
    - ansible-playbook -i inventory/production.yml playbooks/profiles/workstation-artist.yml
  only:
    - main
  when: manual
```

---

## 📋 Implementation Roadmap

### Week 1-2: Foundation
- [ ] Create machine profiles (artist, supervisor, render)
- [ ] Set up inventory structure
- [ ] Create group_vars for each machine type
- [ ] Test profile deployment on 1-2 machines

### Week 3-4: Advanced Features
- [ ] Create provisioning playbook
- [ ] Create update playbook
- [ ] Create health check playbook
- [ ] Test on small group of machines

### Week 5-6: Monitoring & Reporting
- [ ] Set up dashboard
- [ ] Create inventory reports
- [ ] Document procedures
- [ ] Train team

### Week 7-8: CI/CD & Automation
- [ ] Set up GitLab CI
- [ ] Create automated tests
- [ ] Implement approval workflows
- [ ] Full production rollout

---

## 💡 Additional Beneficial Upgrades

### 1. **Secrets Management**
Use Ansible Vault for sensitive data:
```bash
ansible-vault create playbooks/group_vars/secrets.yml
```

### 2. **Backup & Recovery**
Create backup playbook for critical configs:
```yaml
- name: Backup configurations
  hosts: all
  tasks:
    - name: Backup /etc/profile.d
      ansible.builtin.archive:
        path: /etc/profile.d
        dest: /backup/profile.d-{{ ansible_date_time.date }}.tar.gz
```

### 3. **Compliance Checking**
Ensure all machines meet standards:
```yaml
- name: Compliance check
  hosts: all
  tasks:
    - name: Verify SELinux state
      assert:
        that: ansible_selinux.status == "enabled"
    
    - name: Verify firewall running
      assert:
        that: ansible_facts.services['firewalld.service'].state == "running"
```

### 4. **Automated Documentation**
Generate docs from playbooks:
```bash
ansible-doc-generator playbooks/ > docs/playbook-reference.md
```

### 5. **Performance Monitoring**
Track deployment times and optimize:
```yaml
- name: Performance tracking
  hosts: all
  tasks:
    - name: Record start time
      set_fact:
        start_time: "{{ ansible_date_time.epoch }}"
    
    # ... deployment tasks ...
    
    - name: Calculate duration
      debug:
        msg: "Deployment took {{ ansible_date_time.epoch | int - start_time | int }} seconds"
```

---

## 🎓 Best Practices for Template System

1. **Keep profiles DRY** - Use role dependencies
2. **Version control everything** - Git for all configs
3. **Test before production** - Always use --check first
4. **Document machine types** - Clear profile descriptions
5. **Use tags extensively** - Allow selective deployment
6. **Monitor deployments** - Track success/failure rates
7. **Regular audits** - Verify machines match profiles
8. **Automated testing** - CI/CD for all changes

---

## 📊 Expected Benefits

### Efficiency Gains:
- **90% faster** new machine deployment
- **75% reduction** in configuration errors
- **50% less time** on updates and maintenance

### Consistency:
- All machines of same type are identical
- Easy to audit and verify
- Simplified troubleshooting

### Scalability:
- Add 100 machines as easily as 1
- Profiles scale infinitely
- Easy to add new software

### Maintainability:
- Single source of truth
- Clear documentation
- Easy onboarding for new team members

---

**Ready to implement? Start with Phase 1 and build from there!** 🚀

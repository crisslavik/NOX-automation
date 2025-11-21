# NOX-automation Improvement Recommendations

## Overview
Analysis of PAM, login, user accounts, and system environment management across your Ansible automation.

---

## 🔴 CRITICAL Issues

### 1. **Inconsistent ENV Variable Management**
**Current State:**
- Multiple roles use `copy` module for `/etc/profile.d/` scripts
- No idempotency - running multiple times duplicates entries
- Different patterns across roles

**Found in:**
- `playbooks/softwares/rv.yml` - Uses `copy` for `/etc/profile.d/rv.sh`
- `playbooks/softwares/neatvideo.yml` - Uses `copy` for `/etc/profile.d/neatvideo.sh`
- `playbooks/softwares/das-element-lite.yml` - Uses `copy` for `/etc/profile.d/daselement.sh`
- `playbooks/roles/blender/tasks/main.yml` - Uses `copy` for `/etc/profile.d/blender_deadline.sh`
- `playbooks/nvidia_official.yml` - Uses `copy` for `/etc/profile.d/nvidia.sh`
- `playbooks/gnome-config.yml` - Uses `copy` for `/etc/profile.d/Z97-nox-gnome-config.sh`
- `playbooks/wallpaper.yml` - Uses `lineinfile` (good!) for `/etc/profile.d/Z99-nox-wallpaper.sh`

**Recommendation:**
Convert ALL `/etc/profile.d/` management to use `lineinfile` with `regexp` like we did for Nuke:

```yaml
- name: Add ENV variable (idempotent)
  ansible.builtin.lineinfile:
    path: /etc/profile.d/software.sh
    create: yes
    mode: '0644'
    line: 'export VAR_NAME=value'
    regexp: '^export VAR_NAME='
```

---

### 2. **PAM Scripts Not Idempotent**
**Current State:**
- PAM scripts in `domain_join` role use `lineinfile` to add to `/etc/pam.d/system-auth`
- BUT: No check if line already exists with different spacing/formatting
- Could cause duplicate entries

**Found in:**
- `playbooks/domain-join.yml`
- `playbooks/roles/domain_join/tasks/full.yml`

**Current Code:**
```yaml
- name: Add PAM session script
  ansible.builtin.lineinfile:
    path: /etc/pam.d/system-auth
    line: "session optional pam_exec.so /usr/share/libpam-script/pam_script_ses_open"
    insertafter: "^session.*pam_systemd"
    state: present
```

**Recommendation:**
Add `regexp` to ensure idempotency:

```yaml
- name: Add PAM session script (idempotent)
  ansible.builtin.lineinfile:
    path: /etc/pam.d/system-auth
    line: "session optional pam_exec.so /usr/share/libpam-script/pam_script_ses_open"
    regexp: '^session\s+optional\s+pam_exec\.so.*pam_script_ses_open'
    insertafter: "^session.*pam_systemd"
    state: present
```

---

### 3. **SSSD Configuration Conflicts**
**Current State:**
- `domain_join` role has TWO different task files:
  - `playbooks/roles/domain_join/tasks/main.yml` - Uses template
  - `playbooks/roles/domain_join/tasks/full.yml` - Also uses template
- `nice-dcv` role OVERWRITES sssd.conf from static file:
  - `playbooks/roles/nice-dcv/tasks/main.yml` - Copies from `Authentication_SSSD/sssd.conf`

**Problem:**
Running `nice-dcv` role AFTER `domain_join` will overwrite the templated sssd.conf!

**Recommendation:**
1. Consolidate domain_join tasks into single file
2. Remove static sssd.conf copy from nice-dcv role
3. Use template everywhere for consistency
4. Add handler to restart sssd only once

---

## 🟡 HIGH Priority Improvements

### 4. **Centralize /etc/skel Management**
**Current State:**
- Multiple roles independently manage `/etc/skel/` files
- No coordination between roles
- Potential conflicts

**Found in:**
- `nuke` role - Creates `.local/share/applications/`
- `blender` role - Creates `.config/blender/`
- `flameshot` role - Creates `.config/flameshot/`
- `davinci` role - Creates `.local/share/DaVinciResolve/`
- `das-element` role - Creates `.das-element/`
- `neatvideo` role - Creates NeatVideo config

**Recommendation:**
Create a dedicated `skel_manager` role that:
1. Ensures base `/etc/skel/` structure
2. Provides reusable tasks for other roles
3. Validates no conflicts between roles

```yaml
# playbooks/roles/skel_manager/tasks/main.yml
---
- name: Ensure base skel directories
  ansible.builtin.file:
    path: "/etc/skel/{{ item }}"
    state: directory
    mode: '0755'
  loop:
    - .config
    - .local/share/applications
    - Pictures
    - Documents
```

---

### 5. **Inconsistent User Deployment Patterns**
**Current State:**
- Some roles deploy to existing AD users
- Some only use `/etc/skel/`
- Different methods for finding AD users

**Examples:**
- `nuke` role - Finds users with `ansible.builtin.find`, deploys desktop files
- `blender` role - Only uses `/etc/skel/`, no existing user deployment
- `flameshot` role - Uses shell script to deploy to existing users

**Recommendation:**
Create a reusable `ad_user_deploy` role with standardized tasks:

```yaml
# playbooks/roles/ad_user_deploy/tasks/main.yml
---
- name: Find all AD users
  ansible.builtin.find:
    paths: "{{ ad_home_base }}"
    file_type: directory
    recurse: no
  register: ad_users

- name: Deploy config to existing users
  ansible.builtin.copy:
    src: "{{ deploy_source }}"
    dest: "{{ item.path }}/{{ deploy_dest }}"
    owner: "{{ item.path | basename }}"
    group: "{{ item.path | basename }}"
    mode: "{{ deploy_mode | default('0644') }}"
  loop: "{{ ad_users.files }}"
  when: ad_users.files is defined
```

---

### 6. **Profile.d Script Naming Inconsistency**
**Current State:**
- Some use software name: `nuke15.sh`, `rv.sh`, `nvidia.sh`
- Some use prefixes: `Z97-nox-gnome-config.sh`, `Z99-nox-wallpaper.sh`
- No clear naming convention

**Recommendation:**
Standardize naming:
- System-wide configs: `00-nox-system.sh`
- Software-specific: `50-<software>.sh` (e.g., `50-nuke15.sh`)
- User-facing configs: `90-nox-<feature>.sh` (e.g., `90-nox-gnome.sh`)
- Wallpaper/UI: `99-nox-<feature>.sh`

This ensures proper load order (alphabetical).

---

## 🟢 MEDIUM Priority Improvements

### 7. **Consolidate PAM Scripts**
**Current State:**
- 4 separate PAM scripts in `domain_join/files/`:
  - `pam_script_homedir_fix.sh`
  - `pam_script_config_setup.sh`
  - `pam_script_bookmarks.sh`
  - `pam_script_ses_open`

**Recommendation:**
Consider consolidating into a single, well-structured PAM script with functions:

```bash
#!/bin/bash
# /usr/share/libpam-script/nox_pam_session.sh

fix_homedir() {
    # Homedir fix logic
}

setup_config() {
    # Config setup logic
}

setup_bookmarks() {
    # Bookmarks logic
}

# Main execution
fix_homedir
setup_config
setup_bookmarks
```

---

### 8. **Add Validation Tasks**
**Current State:**
- No validation that configurations were applied correctly
- No checks for conflicts between roles

**Recommendation:**
Add validation tasks to each role:

```yaml
- name: Validate ENV variables are set
  ansible.builtin.shell: |
    source /etc/profile.d/software.sh
    [ -n "$VAR_NAME" ]
  changed_when: false
  failed_when: false
  register: env_check

- name: Report validation status
  ansible.builtin.debug:
    msg: "{{ 'ENV variables configured correctly' if env_check.rc == 0 else 'WARNING: ENV variables not set' }}"
```

---

### 9. **Create Master Environment Role**
**Current State:**
- Environment setup scattered across multiple roles
- No single source of truth for system-wide settings

**Recommendation:**
Create `roles/nox_environment/` that:
1. Sets up base `/etc/profile.d/00-nox-base.sh` with common settings
2. Configures system-wide PATH additions
3. Sets up common environment variables
4. Other roles can depend on this

```yaml
# playbooks/roles/nox_environment/meta/main.yml
---
dependencies: []

# playbooks/roles/nuke/meta/main.yml
---
dependencies:
  - role: nox_environment
```

---

### 10. **Improve SSSD Template**
**Current State:**
- Basic sssd.conf template
- No comments or documentation

**Recommendation:**
Enhance template with:
- Comments explaining each section
- Conditional blocks for different scenarios
- Variables for all configurable options

---

## 📋 Implementation Priority

### Phase 1 (Critical - Do First):
1. ✅ Fix Nuke ENV variables (DONE)
2. Convert all `/etc/profile.d/` scripts to use `lineinfile`
3. Fix PAM script idempotency
4. Resolve SSSD configuration conflicts

### Phase 2 (High Priority):
5. Create `skel_manager` role
6. Create `ad_user_deploy` role
7. Standardize profile.d naming

### Phase 3 (Medium Priority):
8. Consolidate PAM scripts
9. Add validation tasks
10. Create master environment role

---

## 🛠️ Quick Wins

### Immediate Actions You Can Take:

1. **Add regexp to all lineinfile tasks** - Prevents duplicates
2. **Remove nice-dcv sssd.conf copy** - Use template instead
3. **Standardize ad_home_base variable** - Currently inconsistent
4. **Add tags to all tasks** - Better control over what runs

---

## 📊 Summary

**Total Issues Found:** 10
- 🔴 Critical: 3
- 🟡 High: 4  
- 🟢 Medium: 3

**Estimated Effort:**
- Phase 1: 4-6 hours
- Phase 2: 6-8 hours
- Phase 3: 4-6 hours

**Benefits:**
- ✅ Idempotent - Safe to run multiple times
- ✅ Consistent - Same patterns everywhere
- ✅ Maintainable - Clear structure
- ✅ Reliable - No conflicts or overwrites
- ✅ Scalable - Easy to add new software

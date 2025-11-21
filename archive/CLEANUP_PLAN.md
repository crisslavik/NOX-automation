# Ansible Playbook Cleanup and Reorganization Plan

## Issues Identified

### 1. **Duplicate Nuke Playbooks**
- `nuke15.yml` and `nuke16.yml` contain identical logic with only version differences
- Both have **malformed YAML** (broken `---` markers, misplaced `import_role`)
- Both have duplicate inline tasks that override the role
- **Problem**: Running both would overwrite `/etc/profile.d/nuke.sh` causing ENV variable conflicts

### 2. **Broken YAML in Multiple Playbooks**
Files with malformed structure:
- `flameshot.yml` - 2 plays + broken inline tasks
- `slack.yml` - role import + orphaned tasks
- `brave.yml` - double `---` + role import + orphaned tasks  
- `krita.yml` - role import + orphaned tasks
- `blender.yml` - role import + orphaned tasks
- `DEV_Util.yml` - role import + orphaned tasks
- `niceDCV.yml` - role import + orphaned tasks
- `nuke15.yml` - broken structure + duplicate logic
- `nuke16.yml` - broken structure + duplicate logic

### 3. **ENV Variable Duplication Problem**
Current issue: `/etc/profile.d/nuke.sh` gets overwritten each time, but the real problem is:
- No idempotency checks for PATH additions
- No checks if ENV variables already exist
- Multiple runs add duplicate entries

## Solutions

### Solution 1: Fix Nuke Playbooks (CRITICAL)

**Consolidate into single parameterized role:**

Create two clean wrapper playbooks:
```yaml
# nuke15.yml
---
- name: Install Foundry Nuke 15
  hosts: all
  become: yes
  roles:
    - role: nuke
      nuke_version: "15.2"
      nuke_major_version: "15"
```

```yaml
# nuke16.yml  
---
- name: Install Foundry Nuke 16
  hosts: all
  become: yes
  roles:
    - role: nuke
      nuke_version: "16.0"
      nuke_major_version: "16"
```

**Update role to handle multiple versions with idempotency:**
- Use `lineinfile` with `regexp` for ENV variables (prevents duplicates)
- Check if version-specific files already exist before creating
- Use unique filenames per version: `/etc/profile.d/nuke{{ nuke_major_version }}.sh`

### Solution 2: Fix All Broken Playbook Wrappers

Replace all broken playbooks with clean role-only wrappers:

```yaml
---
- name: Install Software Name
  hosts: all
  become: yes
  roles:
    - role: software_name
```

### Solution 3: Add Idempotency to ENV Variable Management

For all roles that set ENV variables, use this pattern:

```yaml
- name: Add ENV variable (idempotent)
  lineinfile:
    path: /etc/profile.d/software.sh
    create: yes
    mode: '0644'
    line: 'export VAR_NAME=value'
    regexp: '^export VAR_NAME='
```

For PATH additions:
```yaml
- name: Add to PATH (idempotent)
  lineinfile:
    path: /etc/profile.d/software.sh
    create: yes
    mode: '0644'
    line: 'export PATH="/opt/software/bin:$PATH"'
    regexp: '^export PATH=.*\/opt\/software\/bin'
```

## Implementation Order

1. ✅ Create this cleanup plan document
2. Fix Nuke role for multi-version support with idempotency
3. Fix nuke15.yml and nuke16.yml wrappers
4. Fix all other broken playbook wrappers
5. Add idempotency checks to roles that manage ENV variables
6. Test all fixed playbooks with `ansible-playbook --syntax-check`
7. Document the changes

## Files to Fix

### High Priority (Broken + Duplicates)
- [ ] playbooks/roles/nuke/tasks/main.yml - Add full implementation with idempotency
- [ ] playbooks/roles/nuke/defaults/main.yml - Add version parameters
- [ ] playbooks/softwares/nuke15.yml - Clean wrapper
- [ ] playbooks/softwares/nuke16.yml - Clean wrapper

### High Priority (Broken YAML)
- [ ] playbooks/softwares/flameshot.yml
- [ ] playbooks/softwares/slack.yml
- [ ] playbooks/softwares/brave.yml
- [ ] playbooks/softwares/krita.yml
- [ ] playbooks/softwares/blender.yml
- [ ] playbooks/softwares/DEV_Util.yml
- [ ] playbooks/softwares/niceDCV.yml

### Medium Priority (Add Idempotency)
- [ ] Review all roles for ENV variable management
- [ ] Add lineinfile with regexp for idempotency

## Benefits After Cleanup

1. **No more duplicates** - Single source of truth per software
2. **Idempotent** - Can run multiple times without issues
3. **Clean structure** - Roles contain logic, playbooks are simple wrappers
4. **Version flexibility** - Easy to add Nuke 17, 18, etc.
5. **Works for existing + future users** - /etc/skel + existing user deployment

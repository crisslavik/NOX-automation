NOX-automation playbooks re-organization proposal

Goal: consolidate individual playbooks into a single package (roles + site playbook) to improve maintainability and reuse.

Proposed layout under `playbooks/`:

- site.yml                 # entrypoint playbook that composes roles
- roles/
  - gnome/                 # tasks, handlers, defaults, templates for GNOME config
    - tasks/main.yml
    - handlers/main.yml
    - defaults/main.yml
    - templates/
  - domain_join/           # domain-join logic (realmd, sssd, pam scripts)
    - tasks/main.yml
    - handlers/main.yml
    - defaults/main.yml
    - files/
  - local_cache/           # disk detection/formatting/mounting logic
    - tasks/main.yml
    - defaults/main.yml

Migration plan (quick):
1) Create `site.yml` and role skeletons (done).
2) Migrate tasks from each playbook into the respective role's `tasks/main.yml` using idempotent modules (copy existing blocks verbatim initially).
3) Move large scripts and config files into `roles/<role>/files/` or `templates/` and reference them using `copy` or `template`.
4) Add `defaults/main.yml` to expose configurable variables (domain name, mounts, package lists).
5) Add `meta/main.yml` with dependencies if roles depend on each other.
6) Run `ansible-playbook --syntax-check playbooks/site.yml` and `ansible-lint`.

Contract (for each role):
- Inputs: Ansible facts, role variables (document defaults in `defaults/main.yml`).
- Outputs: Files written to target system, services enabled/started, mount points created.
- Error modes: Missing variables, missing RPM files, interactive prompts (avoid by requiring vars), permission failures.

Edge cases:
- Interactive prompts in playbooks: convert to required vars or `ansible-vault` secrets.
- OS differences: keep conditionals (ansible_distribution, os_family) or provide `when` clauses.
- Large file artifacts (RPMs): keep in `files/` and check `stat` before copy.

Next steps (I can do):
- Convert `gnome-config.yml` into `roles/gnome` (tasks, handlers, files).  (I'll do this first.)
- Convert `domain-join.yml` into `roles/domain_join`, moving `sssd.conf` into a template.
- Add `defaults/main.yml` for role variables and lightweight README usage.
- Run syntax checks and ansible-lint; fix issues.

If you want I can start by migrating `gnome-config.yml` and `domain-join.yml` into roles now. If you prefer a collection-based structure (`ansible-galaxy collection init`), tell me and I'll adapt.

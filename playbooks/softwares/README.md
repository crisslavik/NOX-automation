# playbooks/softwares (deprecated)

This directory was the original home for application-specific playbooks and installer scripts.
The repository has been migrated to a role-based layout under `playbooks/roles/`.

Status summary
- Canonical installation/configuration is now implemented in `playbooks/roles/` (see individual role folders).
- Installer blobs and large build scripts were removed from this directory and moved to the corresponding role `files/` directories where applicable.
- Pure wrapper playbooks that only delegated to roles have been archived to `archive/playbooks-softwares/` and removed from this folder.

What remains in this folder
- A small set of playbooks that contain additional logic (downloads, Flatpak steps, user configuration changes, desktop integration). These need to be migrated into their role's `tasks/main.yml` (recommended), or kept as enriched wrappers if you prefer. Examples:
  - `brave.yml` (flatpak fallback + role import)
  - `chrome.yml` (flatpak + repo steps)
  - `krita.yml` (flatpak)
  - `flameshot.yml` (flatpak, wrapper script creation, gsettings config)
  - `blender.yml` (get_url/unarchive, Deadline integration)
  - `neatvideo.yml` (config, system scripts)
  - `das-element*.yml` (wrapper script + config)
  - `rv.yml` (zip extraction and desktop entries)
  - `nuke15.yml` / `nuke16.yml` (installer checks + desktop entries)

How you can proceed
- To fully complete the migration: for each file above, move inline scripts and content into `playbooks/roles/<role>/files/` and move tasks into `playbooks/roles/<role>/tasks/main.yml`. Afterwards remove the wrapper.
- If you prefer conservative cleanup, archive the files (already done for pure wrappers) and keep the enriched wrappers until you have time to migrate.

Notes
- CI checks (`ansible-playbook --syntax-check`, `ansible-lint`) must be run on your machine or CI runner — the assistant environment doesn't have Ansible installed.

If you want, I can now: (A) archive all remaining files into `archive/playbooks-softwares/` (fast), or (B) migrate a selected wrapper into its role (I recommend `flameshot` or `blender` next).

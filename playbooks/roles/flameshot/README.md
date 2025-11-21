Flameshot role
----------------

This role installs and configures Flameshot using Flatpak (Option B: no installer blobs).

Variables (defaults/main.yml):
- `flameshot_install_method`: 'flatpak' or 'dnf' (default: 'flatpak')
- `flameshot_configure_shortcuts`: boolean (default: true)

Files placed under `files/` include wrapper scripts and default config files applied to `/etc/skel`.

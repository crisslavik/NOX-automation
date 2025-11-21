Role: blender

Installs Blender (download from upstream), creates symlink, desktop entry, and integrates with Deadline repository if available.

Variables (defaults documented in defaults/main.yml):
- blender_tarball_dest: path where tarball will be downloaded on host (/tmp by default)
- blender_install_base: base install path (/opt/blender)
- deadline_repo: path to Deadline repository for plugin integration

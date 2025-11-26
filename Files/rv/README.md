# Autodesk RV Installation Files

Place Autodesk RV installer files in this directory or in the parent Files/ directory.

## Required Files

Download the RV Linux installer from Autodesk and place it here with this exact filename:

- `RV-Linux-Rocky9-Release-2025.0.0.zip`

### Examples:
- `RV-Linux-Rocky9-Release-2025.0.0.zip` (current version)
- Future versions may have different version numbers

## Download Location

Get RV installers from:
https://www.autodesk.com/products/rv/overview

(Requires Autodesk account and appropriate licensing)

## Version Configuration

The RV version and paths are configured in the playbook:

```yaml
rv_final_path: "/opt/Autodesk/RV-2025.0.0"
rv_extract_parent_path: "/opt/Autodesk"
rv_source_zip: "../../Files/RV-Linux-Rocky9-Release-2025.0.0.zip"
```

## Usage

The Ansible playbook will automatically:
1. Install required dependencies (unzip, tcsh, libglvnd-devel, mesa-libGLU, etc.)
2. Create the /opt/Autodesk directory
3. Copy the installer zip from Files/ to the target machine
4. Extract RV to /opt/Autodesk/RV-2025.0.0
5. Create an isolated RV wrapper script with proper environment variables
6. Create desktop entries and protocol handlers for ShotGrid integration
7. Set up symbolic links in /usr/local/bin
8. Clean up temporary files

## Environment Configuration

The RV wrapper script sets these environment variables:
```bash
export RV_HOME="/opt/Autodesk/RV-2025.0.0"
export RV_SUPPORT_PATH=/mnt/Library/pipeline/rv_support_path
export LD_LIBRARY_PATH=$RV_HOME/lib:$LD_LIBRARY_PATH
export PATH=$RV_HOME/bin:$PATH
```

## ShotGrid Integration

The playbook automatically configures the `rv://` protocol handler for ShotGrid integration, allowing direct launch of RV from the web interface.

# NICE DCV Installation Files

Place NICE DCV RPM installer files in this directory.

## Required Files

Download the NICE DCV RPMs from AWS and place them here:

- `nice-dcv-server-*.rpm` (required)
- `nice-dcv-web-viewer-*.rpm` (required)
- `nice-xdcv-*.rpm` (optional)
- `nice-dcv-gltest-*.rpm` (optional)

## Download Location

Get the latest NICE DCV from:
https://download.nice-dcv.com/

Select the appropriate version for Rocky Linux 9 / RHEL 9.

## Usage

The Ansible playbook will automatically:
1. Detect RPMs in this directory
2. Copy them to the target machine
3. Install them using DNF/YUM
4. Clean up temporary files

No manual file copying to target machines is required!

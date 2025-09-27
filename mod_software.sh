#!/bin/bash
# NOX VFX Modular Software Installation - Usage Examples

echo "=== NOX VFX Modular Software Installation Examples ==="
echo

echo "🎯 Benefits of Modular + RPM-Only Approach:"
echo "   ✅ Granular control - install only what you need"
echo "   ✅ Version consistency - exact same versions everywhere"
echo "   ✅ Offline capability - no internet required on workstations"
echo "   ✅ Fast deployment - local files, no downloads"
echo "   ✅ Easy testing - test individual software components"
echo "   ✅ Compliance friendly - pre-approved software packages"
echo

echo "📦 1. Download and prepare RPMs:"
echo "   bash files/scripts/download-rpms.sh"
echo "   # Follow the checklist for manual downloads"
echo "   bash files/scripts/verify-rpms.sh"
echo

echo "🚀 2. Installation Examples:"
echo

echo "   📺 Complete VFX workstation (everything):"
echo "   ansible-playbook playbooks/software/install-all-software.yml"
echo

echo "   🎨 Artist workstation (VFX tools only):"
echo "   ansible-playbook playbooks/custom-software.yml \\"
echo "     -e 'install_chrome=true' \\"
echo "     -e 'install_krita=true install_blender=true install_pureref=true' \\"
echo "     -e 'install_vscode=false install_sublime=false'"
echo

echo "   👨‍💻 Developer workstation (coding tools):"
echo "   ansible-playbook playbooks/custom-software.yml \\"
echo "     -e 'install_chrome=true install_brave=true' \\"
echo "     -e 'install_vscode=true install_sublime=true' \\"
echo "     -e 'install_krita=false install_blender=false install_pureref=false'"
echo

echo "   👔 Manager workstation (minimal):"
echo "   ansible-playbook playbooks/custom-software.yml \\"
echo "     -e 'install_chrome=true install_slack=true' \\"
echo "     -e 'install_vscode=false install_krita=false install_blender=false'"
echo

echo "🔧 3. Individual software installation:"
echo "   # Install just Chrome:"
echo "   ansible-playbook playbooks/software/install-chrome.yml"
echo

echo "   # Install just Krita:"
echo "   ansible-playbook playbooks/software/install-krita.yml"
echo

echo "   # Install just PureRef:"
echo "   ansible-playbook playbooks/software/install-pureref.yml"
echo

echo "🧪 4. Testing and staging:"
echo "   # Test on single machine:"
echo "   ansible-playbook playbooks/software/install-chrome.yml --limit nox-cmp-04"
echo

echo "   # Test new software before rollout:"
echo "   ansible-playbook playbooks/software/install-pureref.yml --limit test-machines"
echo

echo "🎯 5. Department-specific deployments:"
echo "   # All artist workstations:"
echo "   ansible-playbook playbooks/custom-software.yml --limit artists \\"
echo "     -e 'install_krita=true install_blender=true install_pureref=true'"
echo

echo "   # All developer workstations:"
echo "   ansible-playbook playbooks/custom-software.yml --limit developers \\"
echo "     -e 'install_vscode=true install_sublime=true'"
echo

echo "🔄 6. Updates and maintenance:"
echo "   # Update just Chrome across all machines:"
echo "   bash files/scripts/download-rpms.sh  # Get latest Chrome RPM"
echo "   ansible-playbook playbooks/software/install-chrome.yml"
echo

echo "   # Check what's installed:"
echo "   ansible all -m shell -a '/usr/local/bin/nox-software-summary.sh'"
echo

echo "📊 7. Inventory and compliance:"
echo "   # Generate software inventory:"
echo "   ansible all -m shell -a 'rpm -qa | grep -E \"(chrome|code|krita|blender)\" | sort'"
echo

echo "   # Check versions across fleet:"
echo "   ansible all -m shell -a 'google-chrome --version; code --version'"
echo

echo "⚡ 8. Quick combinations:"
echo "   # Essential tools only:"
echo "   ansible-playbook playbooks/custom-software.yml \\"
echo "     -e 'install_chrome=true install_vscode=true install_slack=true'"
echo

echo "   # VFX pipeline essentials:"
echo "   ansible-playbook playbooks/custom-software.yml \\"
echo "     -e 'install_krita=true install_blender=true install_pureref=true'"
echo

echo "=== Choose the approach that fits your workflow! ==="
echo
echo "💡 Pro Tips:"
echo "   • Start with individual software to test your RPMs"
echo "   • Use custom-software.yml for different user types"
echo "   • Keep RPMs updated monthly for security patches"
echo "   • Test updates on staging machines first"

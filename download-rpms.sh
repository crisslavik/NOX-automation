#!/bin/bash
# Enhanced RPM Download Script for NOX VFX - Including PureRef

set -e

BASE_DIR="$(dirname "$0")/../rpms"
mkdir -p "$BASE_DIR"/{browsers,editors,vfx,communication,gnome}

echo "🔽 Downloading NOX VFX Software RPMs..."
echo "📍 Target directory: $BASE_DIR"
echo

# Browsers
echo "📥 Downloading browsers..."
cd "$BASE_DIR/browsers"

echo "  • Google Chrome..."
wget -q --show-progress -O "google-chrome-stable_current_x86_64.rpm" \
  "https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm"

echo "  • Brave Browser..."
# Note: Brave RPM URL changes frequently, this is a fallback approach
BRAVE_URL="https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo"
echo "    ⚠️  Brave requires manual download from brave.com/download"

# Editors  
echo
echo "📥 Downloading editors..."
cd "$BASE_DIR/editors"

echo "  • VS Code..."
wget -q --show-progress -O "code-stable-x86_64.rpm" \
  "https://code.visualstudio.com/sha/download?build=stable&os=linux-rpm-x64"

echo "  • Sublime Text..."
SUBLIME_BUILD="4169"  # Update this to latest build number
wget -q --show-progress -O "sublime_text-4_build_${SUBLIME_BUILD}.rpm" \
  "https://download.sublimetext.com/sublime_text-4_build_${SUBLIME_BUILD}-1.x86_64.rpm"

# VFX Tools
echo
echo "📥 Downloading VFX tools..."
cd "$BASE_DIR/vfx"

echo "  • Krita..."
echo "    ⚠️  Krita RPM not available - will use Flatpak fallback"

echo "  • Blender..."
echo "    ⚠️  Blender RPM not available - will use Flatpak fallback"

echo "  • PureRef..."
echo "    ⚠️  PureRef requires manual download:"
echo "       1. Visit: https://www.pureref.com/download.php"
echo "       2. Download Linux version (.rpm if available, or .tar.gz)"
echo "       3. Save as: files/rpms/vfx/pureref-1.11.1.rpm"
echo "       📝 Note: PureRef is free for non-commercial use"

# Communication
echo
echo "📥 Downloading communication tools..."
cd "$BASE_DIR/communication"

echo "  • Slack..."
echo "    ⚠️  Slack RPM download requires specific version URL"
echo "       Using Flatpak installation instead (recommended)"

# GNOME Tools
echo
echo "📥 GNOME Tools..."
echo "    ℹ️  GNOME Extensions and Tweaks available from AlmaLinux repos"

echo
echo "📊 Download Summary:"
echo "✅ Downloaded automatically:"
find "$BASE_DIR" -name "*.rpm" -exec ls -lh {} \; | awk '{print "   " $9 " (" $5 ")"}'

echo
echo "⚠️  Manual downloads required:"
echo "   • Brave Browser: https://brave.com/download/"
echo "   • PureRef: https://www.pureref.com/download.php"
echo "   • Krita: Will use Flatpak (org.kde.krita)"
echo "   • Blender: Will use Flatpak (org.blender.Blender)"
echo "   • Slack: Will use Flatpak (com.slack.Slack)"

echo
echo "🔧 Next steps:"
echo "1. Download manual RPMs to their respective directories"
echo "2. Run: bash files/scripts/verify-rpms.sh"
echo "3. Deploy: ansible-playbook playbooks/software/install-all-software.yml"

echo
echo "💡 Pro tip: For VFX tools, Flatpak often provides newer versions"
echo "   and better sandboxing than RPM packages."

# Create a checklist file
cat > "$BASE_DIR/../download-checklist.md" << 'EOF'
# NOX VFX Software Download Checklist

## ✅ Automatically Downloaded
- [x] Google Chrome
- [x] VS Code  
- [x] Sublime Text

## ⏳ Manual Downloads Required

### Browsers
- [ ] **Brave Browser**
  - URL: https://brave.com/download/
  - File: `files/rpms/browsers/brave-browser-stable-1.x.x.rpm`
  - Notes: Download the .rpm package for Linux

### VFX Tools  
- [ ] **PureRef** 
  - URL: https://www.pureref.com/download.php
  - File: `files/rpms/vfx/pureref-1.11.1.rpm`
  - Notes: Free for non-commercial use, may need account registration

### Alternative: Use Flatpak (Recommended)
- [ ] **Krita** - `org.kde.krita` (Flatpak)
- [ ] **Blender** - `org.blender.Blender` (Flatpak)  
- [ ] **Slack** - `com.slack.Slack` (Flatpak)

## 🔍 Verification Steps
1. Run: `bash files/scripts/verify-rpms.sh`
2. Check all RPMs are valid and not corrupted
3. Test installation on one machine first

## 🚀 Deployment Commands

### Install Everything
```bash
ansible-playbook playbooks/software/install-all-software.yml
```

### Install Individual Software
```bash
# Only browsers
ansible-playbook playbooks/software/install-chrome.yml
ansible-playbook playbooks/software/install-brave.yml

# Only VFX tools
ansible-playbook playbooks/software/install-krita.yml
ansible-playbook playbooks/software/install-blender.yml
ansible-playbook playbooks/software/install-pureref.yml

# Custom selection
ansible-playbook playbooks/custom-software.yml \
  -e "install_chrome=true install_krita=true install_pureref=true" \
  -e "install_browsers=false install_editors=false"
```

EOF

echo "📋 Download checklist created: $BASE_DIR/../download-checklist.md"

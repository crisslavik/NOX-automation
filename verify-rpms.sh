#!/bin/bash
# Verify RPM integrity and versions
# Place this script in the main project folder

BASE_DIR="files/rpms"

echo "🔍 Verifying NOX VFX RPM packages..."
echo "📍 Checking directory: $BASE_DIR"
echo

if [ ! -d "$BASE_DIR" ]; then
    echo "❌ RPM directory not found: $BASE_DIR"
    echo "   Run ./download-rpms.sh first to create structure and download RPMs"
    exit 1
fi

total_rpms=0
valid_rpms=0

for category in browsers editors vfx communication; do
    if [ -d "$BASE_DIR/$category" ]; then
        echo "📁 $category:"
        found_rpms=false
        
        for rpm in "$BASE_DIR/$category"/*.rpm; do
            if [ -f "$rpm" ]; then
                found_rpms=true
                total_rpms=$((total_rpms + 1))
                filename=$(basename "$rpm")
                
                # Check if RPM is valid
                if rpm -qp "$rpm" > /dev/null 2>&1; then
                    valid_rpms=$((valid_rpms + 1))
                    version=$(rpm -qp --qf '%{VERSION}-%{RELEASE}' "$rpm" 2>/dev/null)
                    size=$(ls -lh "$rpm" | awk '{print $5}')
                    echo "  ✅ $filename (v$version, $size)"
                else
                    echo "  ❌ $filename (CORRUPTED OR INVALID)"
                fi
            fi
        done
        
        if [ "$found_rpms" = false ]; then
            echo "  ℹ️  No RPM files found"
        fi
        echo
    else
        echo "📁 $category: Directory not found"
        echo
    fi
done

echo "📊 Summary: $valid_rpms/$total_rpms RPMs are valid"

if [ $total_rpms -eq 0 ]; then
    echo "⚠️  No RPM files found. Run ./download-rpms.sh to download software."
    echo ""
    echo "💡 Manual downloads may be required for:"
    echo "   • Brave Browser"
    echo "   • PureRef"
    exit 1
elif [ $valid_rpms -eq $total_rpms ]; then
    echo "🎉 All RPMs are ready for deployment!"
    echo ""
    echo "🚀 Next steps:"
    echo "   # Test individual software:"
    echo "   ansible-playbook playbooks/software/install-chrome.yml --limit nox-cmp-04"
    echo ""
    echo "   # Deploy all software:"
    echo "   ansible-playbook playbooks/software/install-all-software.yml"
    exit 0
else
    echo "⚠️  Some RPMs need attention:"
    echo "   • Re-download corrupted files"
    echo "   • Check manual downloads: files/download-checklist.md"
    echo "   • Run ./download-rpms.sh again"
    echo ""
    echo "🔍 Detailed issues:"
    # Show which specific RPMs failed
    for category in browsers editors vfx communication; do
        if [ -d "$BASE_DIR/$category" ]; then
            for rpm in "$BASE_DIR/$category"/*.rpm; do
                if [ -f "$rpm" ]; then
                    if ! rpm -qp "$rpm" > /dev/null 2>&1; then
                        echo "   ❌ $(basename "$rpm") in $category/"
                    fi
                fi
            done
        fi
    done
    exit 1
fi

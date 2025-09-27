#!/bin/bash
# Generate Ansible variables from available RPMs
# Place this script in the main project folder

BASE_DIR="files/rpms"
OUTPUT_FILE="group_vars/all/rpm_inventory.yml"

echo "📝 Generating RPM inventory..."

# Create group_vars directory if it doesn't exist
mkdir -p "$(dirname "$OUTPUT_FILE")"

# Generate the inventory file
cat > "$OUTPUT_FILE" << EOF
---
# Auto-generated RPM inventory
# Generated on: $(date)
# Do not edit manually - run ./update-rpm-inventory.sh instead

available_rpms:
EOF

# Check if RPM directory exists
if [ ! -d "$BASE_DIR" ]; then
    echo "  # No RPMs found - run ./download-rpms.sh first" >> "$OUTPUT_FILE"
    echo "⚠️  RPM directory not found: $BASE_DIR"
    echo "   Run ./download-rpms.sh first"
    exit 1
fi

total_rpms=0

for category in browsers editors vfx communication; do
    if [ -d "$BASE_DIR/$category" ]; then
        has_rpms=false
        
        # Check if category has any RPMs
        for rpm in "$BASE_DIR/$category"/*.rpm; do
            if [ -f "$rpm" ]; then
                has_rpms=true
                break
            fi
        done
        
        if [ "$has_rpms" = true ]; then
            echo "  $category:" >> "$OUTPUT_FILE"
            
            for rpm in "$BASE_DIR/$category"/*.rpm; do
                if [ -f "$rpm" ]; then
                    filename=$(basename "$rpm")
                    
                    # Try to get package info, fallback to filename parsing
                    if package_name=$(rpm -qp --qf '%{NAME}' "$rpm" 2>/dev/null); then
                        version=$(rpm -qp --qf '%{VERSION}' "$rpm" 2>/dev/null)
                        description=$(rpm -qp --qf '%{SUMMARY}' "$rpm" 2>/dev/null || echo "")
                    else
                        # Fallback: parse from filename  
                        package_name=$(echo "$filename" | sed 's/-[0-9].*\.rpm$//' | sed 's/_.*\.rpm$//')
                        version="unknown"
                        description="RPM file (package info unavailable)"
                    fi
                    
                    total_rpms=$((total_rpms + 1))
                    
                    cat >> "$OUTPUT_FILE" << EOF
    - name: "$package_name"
      file: "$category/$filename"
      version: "$version"
      category: "$category"
      description: "$description"
EOF
                fi
            done
        fi
    fi
done

if [ $total_rpms -eq 0 ]; then
    echo "  # No valid RPM files found" >> "$OUTPUT_FILE"
    echo "❌ No RPM files found"
    echo "   Run ./download-rpms.sh to download software packages"
else
    echo "✅ RPM inventory updated: $OUTPUT_FILE"
    echo "📦 Found $total_rpms RPM packages"
fi

echo ""
echo "🔧 Usage in playbooks:"
echo "   # Install specific category:"
echo "   - name: Install browsers from inventory"
echo "     ansible.builtin.copy:"
echo "       src: \"files/rpms/{{ item.file }}\""
echo "       dest: \"/tmp/{{ item.file | basename }}\""
echo "     loop: \"{{ available_rpms.browsers }}\""
echo ""
echo "   - name: Install from copied RPMs"
echo "     ansible.builtin.dnf:"
echo "       name: \"/tmp/{{ item.file | basename }}\""
echo "     loop: \"{{ available_rpms.browsers }}\""
echo ""
echo "📋 View inventory:"
echo "   cat $OUTPUT_FILE"

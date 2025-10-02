#!/bin/bash
# A simple script to copy the public SSH key to multiple machines.
# This assumes you have the same root password for all machines.
# --- IMPORTANT ---
# 1. This script now uses your Ansible inventory file to get the list of hosts.
#    It will now use hostnames directly, assuming they are resolvable via DNS.
#    
# 2. Create a file named 'password.txt' in the same directory.
#    Write your root password on the first line.
#    
#    chmod 600 password.txt  # <-- SECURE THIS FILE!

# ANSI color codes for messages
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# User and password variables
USER="root"
PASSWORD_FILE="password.txt"
ANSIBLE_INVENTORY_FILE="$HOME/ansible/hosts.ini"

# Check if the necessary files exist
if [ ! -f "$PASSWORD_FILE" ]; then
    echo "Error: Password file '$PASSWORD_FILE' not found."
    exit 1
fi

if [ ! -f "$ANSIBLE_INVENTORY_FILE" ]; then
    echo "Error: Ansible inventory file '$ANSIBLE_INVENTORY_FILE' not found."
    exit 1
fi

echo "Searching for hosts in $ANSIBLE_INVENTORY_FILE..."

# Parse hosts from Ansible inventory
# Skip empty lines, comments, group headers, and variable sections
HOSTS_FOUND=$(awk '
    # Skip empty lines and comments
    /^\s*$/ { next }
    /^\s*#/ { next }
    
    # Skip group headers
    /^\s*\[.*\]/ { 
        # Check if this is a :vars section
        if ($0 ~ /:vars\]/) {
            in_vars_section = 1
        } else {
            in_vars_section = 0
        }
        next 
    }
    
    # Skip lines in vars sections
    in_vars_section { next }
    
    # Extract hostname or ansible_host value
    {
        if ($0 ~ /ansible_host=/) {
            match($0, /ansible_host=([^ \t]+)/, arr)
            print arr[1]
        } else {
            print $1
        }
    }
' "$ANSIBLE_INVENTORY_FILE")

if [ -z "$HOSTS_FOUND" ]; then
    echo "Warning: No hosts were found in the inventory file."
    exit 0
fi

echo "Found hosts:"
echo "$HOSTS_FOUND"
echo ""

# Loop through each host found in the Ansible inventory file.
for HOST in $HOSTS_FOUND; do
    echo "--- Attempting to copy key to $HOST ---"
    
    # Use sshpass to provide the password non-interactively
    sshpass -f "$PASSWORD_FILE" ssh-copy-id \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        "$USER@$HOST"
        
    # Check the exit status of the previous command
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}SUCCESS: Key successfully added or already present on $HOST.${NC}"
    else
        echo -e "${RED}FAILURE: Failed to add key to $HOST. Check password, permissions, or connectivity.${NC}"
    fi
    echo
done

# --- CLEAN UP ---
# It's a good security practice to delete the password file when done.
# rm -f "$PASSWORD_FILE"
# Uncomment the line above to automatically delete the password file after use.

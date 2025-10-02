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
ANSIBLE_INVENTORY_FILE="hosts.ini"

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
echo "Searching for hosts in $ANSIBLE_INVENTORY_FILE..."

# Parse Ansible inventory and extract actual hostnames/IPs
# This handles:
# - Lines with "ansible_host=" variable (extracts the IP/hostname)
# - Plain hostname entries
# - Ignores comments, blank lines, and group headers
HOSTS_FOUND=$(awk '
    # Skip empty lines, comments, and group headers
    /^\s*$/ { next }
    /^\s*#/ { next }
    /^\s*\[.*\]/ { next }
    
    # If line contains ansible_host=, extract that value
    /ansible_host=/ {
        match($0, /ansible_host=([^ \t]+)/, arr)
        print arr[1]
        next
    }
    
    # Otherwise, print the first field (the hostname)
    {
        print $1
    }
' "$ANSIBLE_INVENTORY_FILE")

if [ -z "$HOSTS_FOUND" ]; then
    echo "Warning: No hosts were found in the inventory file. Please check the file format."
    exit 0
fi
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

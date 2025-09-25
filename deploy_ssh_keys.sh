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
# A more flexible way to find hosts, handling commented lines and group names.
# This finds lines that are not empty and do not start with a hash or bracket.
HOSTS_FOUND=$(grep -vE '^\s*#|^\s*\[|^\s*$' "$ANSIBLE_INVENTORY_FILE")

if [ -z "$HOSTS_FOUND" ]; then
    echo "Warning: No hosts were found in the inventory file. Please check the file format."
    exit 0
fi

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

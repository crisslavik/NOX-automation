#!/bin/bash

# A simple script to copy the public SSH key to multiple machines.
# This assumes you have the same root password for all machines.

# --- IMPORTANT ---
# 1. This script now uses your Ansible inventory file to get the list of hosts.
#    It looks for lines containing 'ansible_host='.
#    
# 2. Create a file named 'password.txt' in the same directory.
#    Write your root password on the first line.
#    
#    chmod 600 password.txt  # <-- SECURE THIS FILE!

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

# Loop through each host in the Ansible inventory file.
# We use grep and awk to extract only the IP addresses from the 'ansible_host=' lines.
for HOST in $(grep "ansible_host=" "$ANSIBLE_INVENTORY_FILE" | awk -F'=' '{print $2}'); do
    echo "--- Copying key to $HOST ---"
    
    # Use sshpass to provide the password non-interactively
    sshpass -f "$PASSWORD_FILE" ssh-copy-id \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        "$USER@$HOST"
        
    if [ $? -eq 0 ]; then
        echo "Successfully added key to $HOST."
    else
        echo "Failed to add key to $HOST. Check password or connectivity."
    fi
    echo
done

# --- CLEAN UP ---
# It's a good security practice to delete the password file when done.
# rm -f "$PASSWORD_FILE"
# Uncomment the line above to automatically delete the password file after use.

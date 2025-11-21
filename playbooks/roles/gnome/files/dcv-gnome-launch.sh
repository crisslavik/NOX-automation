#!/bin/bash
# DCV Session Launch Script with NOX GNOME Configuration

# Wait for DCV session to stabilize
sleep 5

# Apply NOX GNOME configuration
if [ -x /usr/local/bin/set-nox-gnome-config.sh ]; then
    /usr/local/bin/set-nox-gnome-config.sh &
fi

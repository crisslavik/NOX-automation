#!/bin/bash
sleep 5
if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
    if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
        export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
    fi
    
    gsettings set org.gnome.shell.keybindings screenshot '[]' 2>/dev/null || true
    gsettings set org.gnome.settings-daemon.plugins.media-keys screenshot '[]' 2>/dev/null || true

    # Create or update custom binding for Flameshot
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/flameshot-gui/ name 'Flameshot Screenshot' 2>/dev/null || true
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/flameshot-gui/ command '/usr/local/bin/flameshot gui' 2>/dev/null || true
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/flameshot-gui/ binding 'Print' 2>/dev/null || true
fi

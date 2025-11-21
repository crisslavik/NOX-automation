#!/bin/bash
echo "=== NOX VFX GNOME Configuration Verification ==="

echo
if [ "$XDG_CURRENT_DESKTOP" != "GNOME" ]; then
    echo "❌ Not in GNOME session"
    echo "   Please run this from a GNOME desktop environment"
    exit 1
fi

echo "🖥️ GNOME Environment:"
echo "   Session: $XDG_SESSION_TYPE"
echo "   Desktop: $XDG_CURRENT_DESKTOP"
echo "   Display: $DISPLAY"
[ -n "$WAYLAND_DISPLAY" ] && echo "   Wayland Display: $WAYLAND_DISPLAY"
echo

echo "🎨 Theme Configuration:"
theme=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null)
color_scheme=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null)
echo "   Theme: $theme"
echo "   Color Scheme: $color_scheme"

echo

echo "🔧 Extensions:"
enabled_extensions=$(gsettings get org.gnome.shell enabled-extensions 2>/dev/null)
if [[ "$enabled_extensions" == *"dash-to-dock"* ]]; then
    echo "   ✅ Dash to Dock enabled"
else
    echo "   ⚠️ Extensions may need attention"
fi

echo

echo "⚡ Interface Settings:"
battery=$(gsettings get org.gnome.desktop.interface show-battery-percentage 2>/dev/null)
hot_corners=$(gsettings get org.gnome.desktop.interface enable-hot-corners 2>/dev/null)
echo "   Battery percentage: $battery"
echo "   Hot corners: $hot_corners"
echo

echo "📁 File Manager:"
list_view=$(gsettings get org.gnome.nautilus.preferences default-folder-viewer 2>/dev/null)
sort_dirs=$(gsettings get org.gtk.settings.file-chooser sort-directories-first 2>/dev/null)
echo "   Default view: $list_view"
echo "   Sort directories first: $sort_dirs"
echo

# Check for DCV
if [ -x /usr/bin/dcv ]; then
    echo "🖥️ Nice DCV: Installed"
    if [ -f /etc/dcv/dcv.conf.d/gnome-optimization.conf ]; then
        echo "   ✅ DCV GNOME optimizations configured"
    fi
fi

echo

# Check logs
log_file="/tmp/nox-gnome-config-$(whoami).log"
if [ -f "$log_file" ]; then
    echo "📋 Configuration Log:"
    echo "   Location: $log_file"
    echo "   Last run: $(stat -c %y "$log_file" 2>/dev/null | cut -d. -f1)"
fi

echo

# Check configuration flag
config_flag="$HOME/.config/nox-gnome-configured"
if [ -f "$config_flag" ]; then
    echo "✅ Configuration Status: Applied"
    echo "   Flag file: $config_flag"
else
    echo "⚠️ Configuration Status: Not yet applied"
fi

echo

echo "🎯 NOX VFX GNOME Configuration: Ready for VFX Work!"

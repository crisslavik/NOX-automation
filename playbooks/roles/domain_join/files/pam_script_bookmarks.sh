#!/bin/bash
# This script adds NFS mounts as bookmarks in GNOME Files

USER_HOME=$(eval echo ~$PAM_USER)
BOOKMARKS_FILE="$USER_HOME/.config/gtk-3.0/bookmarks"

mkdir -p "$USER_HOME/.config/gtk-3.0"

# Add public mounts bookmarks for all users
{% for mount in nfs_mounts_public %}
BOOKMARK="file:///mnt/{{ mount.dest }} {{ mount.dest }}"
if ! grep -Fxq "$BOOKMARK" "$BOOKMARKS_FILE" 2>/dev/null; then
    echo "$BOOKMARK" >> "$BOOKMARKS_FILE"
fi
{% endfor %}

# Add NOX Admins bookmarks if user is member of the group
if id -nG "$PAM_USER" | grep -qw "nox-admins"; then
    {% for mount in nfs_mounts_noxadmins %}
    BOOKMARK="file:///mnt/{{ mount.dest }} {{ mount.dest }}"
    if ! grep -Fxq "$BOOKMARK" "$BOOKMARKS_FILE" 2>/dev/null; then
        echo "$BOOKMARK" >> "$BOOKMARKS_FILE"
    fi
    {% endfor %}
fi

USER_UID=$(id -u "$PAM_USER")
USER_GID=$(id -g "$PAM_USER")
chown "$USER_UID:$USER_GID" "$BOOKMARKS_FILE"
chmod 644 "$BOOKMARKS_FILE"

exit 0

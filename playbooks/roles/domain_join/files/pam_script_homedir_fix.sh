#!/bin/bash
# Fix home directory ownership for AD users

USER_HOME=$(eval echo ~$PAM_USER)

if [ -d "$USER_HOME" ]; then
    USER_UID=$(id -u "$PAM_USER")
    USER_GID=$(id -g "$PAM_USER")

    HOME_OWNER=$(stat -c '%U' "$USER_HOME")
    if [ "$HOME_OWNER" = "root" ]; then
        chown "$USER_UID:$USER_GID" "$USER_HOME"
        chmod 700 "$USER_HOME"
        logger "Fixed home directory ownership for $PAM_USER"
    fi

    chmod 700 "$USER_HOME"
    restorecon -R "$USER_HOME" 2>/dev/null || true
fi

exit 0

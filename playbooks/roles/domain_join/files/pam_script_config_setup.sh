#!/bin/bash
# Setup .config directory for AD users on login

USER_HOME=$(eval echo ~$PAM_USER)

if [ -d "$USER_HOME" ]; then
    if [ ! -d "$USER_HOME/.config" ]; then
        mkdir -p "$USER_HOME/.config/dconf"

        USER_UID=$(id -u "$PAM_USER")
        USER_GID=$(id -g "$PAM_USER")
        chown -R "$USER_UID:$USER_GID" "$USER_HOME/.config"

        chmod 700 "$USER_HOME/.config"
        chmod 700 "$USER_HOME/.config/dconf"

        restorecon -R "$USER_HOME/.config" 2>/dev/null || true
        logger "Created .config directory for $PAM_USER"
    fi

    if [ -d "$USER_HOME/.config" ] && [ ! -w "$USER_HOME/.config" ]; then
        USER_UID=$(id -u "$PAM_USER")
        USER_GID=$(id -g "$PAM_USER")
        chown -R "$USER_UID:$USER_GID" "$USER_HOME/.config"
        chmod 700 "$USER_HOME/.config"
        restorecon -R "$USER_HOME/.config" 2>/dev/null || true
        logger "Fixed .config permissions for $PAM_USER"
    fi
fi

exit 0

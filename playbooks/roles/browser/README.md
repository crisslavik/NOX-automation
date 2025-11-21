Role: browser.brave

Installs Brave Browser. Strategy:
- try system package (dnf)
- if unavailable, ensure flatpak is present and install from Flathub

Variables:
- browser_brave_flatpak_name: com.brave.Browser

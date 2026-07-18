# Universal Window Manager Sandbox

A dynamic, distro-agnostic shell script designed to let Linux users safely test various Tiling Window Managers and Wayland Compositors without altering their primary desktop configurations or permanently altering their system packages.

## Features

- **Zero-Trace Testing:** Automatically installs packages, launches an isolated environment, and purges all packages and configuration directories cleanly upon exit.
- **Dynamic Active Environment Filtering:** Detects if you are already running i3, AwesomeWM, or Hyprland and automatically removes that option from the menu to prevent nesting conflicts.
- **Multi-Distro Engine:** Identifies your Linux distribution via /etc/os-release and translates package names and installer arguments dynamically across multiple package managers.
- **Hybrid X11 and Wayland Sandboxing:** Leverages Xephyr to create standalone, embedded display layers for X11 environments, and utilizes built-in nesting flags for Wayland compositors.

---

## Supported Distributions

The sandbox currently includes dynamic configuration translations for:
- **Arch Linux** (including EndeavourOS, Manjaro, Omarchy)
- **Debian / Ubuntu** (including Pop!_OS, Linux Mint)
- **Fedora** (including Nobara)
- **openSUSE** (Tumbleweed, Leap)

---

## How It Works

1. **Detection:** The script reads environment variables (such as $HYPRLAND_INSTANCE_SIGNATURE) and root display properties to identify your host environment.
2. **Filtering:** It maps choices to a dynamic array, filtering out your active desktop so you can only choose alternate interfaces to test.
3. **Isolation:** For X11 layouts, it spins up an isolated virtual display architecture (Xephyr :1) running as a nested window application.
4. **The Trap and Purge:** The script hooks directly into SIGINT and SIGTERM signals. If you close the terminal or hit Ctrl+C, it triggers the internal cleanup routine to fully uninstall the target window managers and delete their generated configuration files.

---

## Quick Start Guide

Clone the repository, grant execution permissions to the shell script, and launch:

```bash
git clone [https://github.com/azzenabidi/wmsandox](https://github.com/azzenabidi/wm-sandbox.git)
cd wm-sandbox
chmod +x wm-sandbox.sh
./wm-sandbox.sh

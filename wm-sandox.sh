#!/usr/bin/env bash

# ==============================================================================
# DYNAMIC MULTI-DISTRO WINDOW MANAGER SANDBOX
# Auto-detects active desktops, cross-checks Linux distribution types, and 
# dynamically handles multi-distro variations (including openSUSE).
# ==============================================================================

# 1. IDENTIFY THE LINUX DISTRIBUTION
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo "[!] /etc/os-release not found. Unable to identify distribution."
    exit 1
fi

# 2. DEFINE SYSTEM ENGINE MAPS
INSTALL_CMD=""
UNINSTALL_CMD=""
XEPHYR_PKG=""

case "$DISTRO" in
    arch|endeavouros|manjaro)
        INSTALL_CMD="sudo pacman -Sy --needed --noconfirm"
        UNINSTALL_CMD="sudo pacman -Rns --noconfirm"
        XEPHYR_PKG="xorg-server-xephyr"
        I3_PKG="i3-wm"
        AWESOME_PKG="awesome"
        BSPWM_PKG="bspwm"
        HYPR_PKG="hyprland"
        ;;
    debian|ubuntu|pop|mint)
        INSTALL_CMD="sudo apt-get update && sudo apt-get install -y"
        UNINSTALL_CMD="sudo apt-get purge -y && sudo apt-get autoremove -y"
        XEPHYR_PKG="xserver-xephyr"
        I3_PKG="i3-wm"
        AWESOME_PKG="awesome"
        BSPWM_PKG="bspwm"
        HYPR_PKG="hyprland"
        ;;
    fedora|nobara)
        INSTALL_CMD="sudo dnf install -y"
        UNINSTALL_CMD="sudo dnf remove -y"
        XEPHYR_PKG="xorg-x11-server-Xephyr"
        I3_PKG="i3-wm"
        AWESOME_PKG="awesome"
        BSPWM_PKG="bspwm"
        HYPR_PKG="hyprland"
        ;;
    opensuse-tumbleweed|opensuse-leap|opensuse)
        # --no-recommends skips massive companion metadata downloads
        INSTALL_CMD="sudo zypper --non-interactive in --no-recommends"
        UNINSTALL_CMD="sudo zypper --non-interactive rm --clean-deps"
        XEPHYR_PKG="xorg-x11-server-extra" # openSUSE bundles Xephyr here
        I3_PKG="i3"
        AWESOME_PKG="awesome"
        BSPWM_PKG="bspwm"
        HYPR_PKG="hyprland"
        ;;
    *)
        echo "[!] Unsupported or unverified distribution: $DISTRO"
        echo "[*] Open an issue or submit a PR on GitHub to add support!"
        exit 1
        ;;
esac

# 3. AUTO-DETECT CURRENT RUNNING ENVIRONMENT
CURRENT_ENV=""
if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    CURRENT_ENV="hyprland"
elif [ -n "$I3SOCK" ] || xprop -root _NET_SUPPORTING_WM_CHECK &>/dev/null && xprop -id $(xprop -root _NET_SUPPORTING_WM_CHECK | awk '{print $NF}') _NET_WM_NAME | grep -qi "i3"; then
    CURRENT_ENV="i3"
elif xprop -root _NET_SUPPORTING_WM_CHECK &>/dev/null && xprop -id $(xprop -root _NET_SUPPORTING_WM_CHECK | awk '{print $NF}') _NET_WM_NAME | grep -qi "awesome"; then
    CURRENT_ENV="awesome"
elif [ -n "$XDG_CURRENT_DESKTOP" ]; then
    CURRENT_ENV=$(echo "$XDG_CURRENT_DESKTOP" | tr '[:upper:]' '[:lower:]')
fi

# 4. MAP THE SAMPLE OPTIONS POOL
ALL_NAMES=("i3-wm" "AwesomeWM" "bspwm" "Hyprland")
ALL_WMS=("i3" "awesome" "bspwm" "hyprland")
ALL_PKGS=("$I3_PKG" "$AWESOME_PKG" "$BSPWM_PKG" "$HYPR_PKG")

# 5. DYNAMICALLY FILTER CHOICES BASED ON ENVIRONMENT
AVAILABLE_NAMES=()
AVAILABLE_WMS=()
AVAILABLE_PKGS=("$XEPHYR_PKG")

for i in "${!ALL_WMS[@]}"; do
    if [ "${ALL_WMS[$i]}" == "$CURRENT_ENV" ]; then
        continue # Hide what the user is already running
    fi
    AVAILABLE_NAMES+=("${ALL_NAMES[$i]}")
    AVAILABLE_WMS+=("${ALL_WMS[$i]}")
    AVAILABLE_PKGS+=("${ALL_PKGS[$i]}")
done

# 6. UNINSTALLER PURGE BLOCK
cleanup() {
    echo -e "\n\n[*] Purging sandbox packages and configs..."
    killall Xephyr 2>/dev/null
    killall hyprland 2>/dev/null
    
    $UNINSTALL_CMD "${AVAILABLE_PKGS[@]}"
    
    for wm in "${AVAILABLE_WMS[@]}"; do rm -rf "$HOME/.config/$wm"; done
    rm -f /tmp/i3-test.sock
    echo "[✓] System configuration restored cleanly!" && exit 0
}
trap cleanup SIGINT SIGTERM

# 7. MAIN INTERACTIVE EXECUTION
echo "============================================="
echo "       UNIVERSAL WINDOW MANAGER SANDBOX      "
echo "============================================="
echo "[*] Distro Platform identified: $DISTRO"
if [ -n "$CURRENT_ENV" ]; then
    echo "[*] Desktop Active: $CURRENT_ENV (Filtered out of choices)"
fi
echo "---------------------------------------------"

echo "[+] Temporarily downloading sandbox targets..."
$INSTALL_CMD "${AVAILABLE_PFX[@]}" "${AVAILABLE_PKGS[@]}"

while true; do
    echo -e "\nAvailable Sandbox Environments:"
    for i in "${!AVAILABLE_NAMES[@]}"; do
        echo "$((i+1))) Test ${AVAILABLE_NAMES[$i]}"
    done
    
    EXIT_OPTION=$(( ${#AVAILABLE_NAMES[@]} + 1 ))
    echo "$EXIT_OPTION) Exit & Clean System"
    echo "---"
    read -p "Select option (1-$EXIT_OPTION): " ch
    
    if [[ "$ch" == "$EXIT_OPTION" ]]; then cleanup; fi
    
    if [[ "$ch" =~ ^[0-9]+$ ]] && [ "$ch" -ge 1 ] && [ "$ch" -lt "$EXIT_OPTION" ]; then
        target_wm="${AVAILABLE_WMS[$((ch-1))]}"
        echo "[+] Booting $target_wm sandbox..."
        
        if [ "$target_wm" == "hyprland" ]; then
            hyprland --config /dev/null & 
        else
            echo "[!] Tip: Use Alt/Mod1 key to prevent primary shortcut overlap!"
            Xephyr -br -ac -noreset -screen 1280x720 :1 & sleep 1
            if [ "$target_wm" == "i3" ]; then
                env I3SOCK=/tmp/i3-test.sock DISPLAY=:1 i3 &
            else
                DISPLAY=:1 "$target_wm" &
            fi
        fi
    else
        echo "[!] Choice out of range."
    fi
done

#!/bin/bash

# =========================================================================
# Android USB Reverse Tethering Script V3.0 (Linux)
# Features: Gnirehtet Auto-Fallback, Custom DNS, Auto-ADB, Notifications
# Usage: ./usb-tether-bridge.sh [start|stop]
# Author: Nkosilathi Koma
# =========================================================================

ACTION=${1:-start}

# 1. Native Linux Desktop Notifications
notify() {
    # Run notify-send as the real user if called via sudo
    if [ -n "$SUDO_USER" ]; then
        sudo -u "$SUDO_USER" notify-send "USB Tether Bridge" "$1" --icon=network-transmit-receive -t 4000 2>/dev/null || echo "💬 $1"
    else
        notify-send "USB Tether Bridge" "$1" --icon=network-transmit-receive -t 4000 2>/dev/null || echo "💬 $1"
    fi
}

# Wrap ADB to NEVER start the daemon as root
adb_wrapper() {
    if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
        sudo -u "$SUDO_USER" adb "$@"
    else
        adb "$@"
    fi
}

# Ensure configuration exists
USER_HOME=$(eval echo "~${SUDO_USER:-$USER}")
CONFIG_DIR="$USER_HOME/.config/usb-tether-bridge"
CONFIG_FILE="$CONFIG_DIR/config.env"
GNIREHTET_DIR="$USER_HOME/.local/share/usb-tether-bridge/gnirehtet"

if [ ! -f "$CONFIG_FILE" ]; then
    mkdir -p "$CONFIG_DIR"
    echo "DNS_1=8.8.8.8" > "$CONFIG_FILE"
    echo "DNS_2=1.1.1.1" >> "$CONFIG_FILE"
fi
source "$CONFIG_FILE"

# 1. Detect active PC interface (Wi-Fi or Ethernet)
HOST_IFACE=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $5}')
if [ -z "$HOST_IFACE" ]; then
    notify "❌ Could not detect PC internet connection."
    exit 1
fi

# 🛑 STOP MODE: Clean up Routing, Firewall, and Gnirehtet
if [ "$ACTION" == "stop" ]; then
    echo "🛑 Stopping tethering and cleaning up..."
    
    # Gracefully command the paired Android phone to destroy the VPN connection
    if [ -f "$GNIREHTET_DIR/gnirehtet" ] && command -v adb_wrapper >/dev/null 2>&1; then
        DEVICES=($(adb_wrapper devices | grep -E "\bdevice$" | awk '{print $1}'))
        for DEV in "${DEVICES[@]}"; do
            sudo -u "${SUDO_USER:-$USER}" "$GNIREHTET_DIR/gnirehtet" stop "$DEV" >/dev/null 2>&1
        done
    fi

    # Kill any active Gnirehtet relays
    pkill -f "gnirehtet" >/dev/null 2>&1
    
    # Calculate native bandwidth (from iptables/interfaces)
    # Removing iptables and NAT
    sudo iptables -F
    sudo iptables -t nat -F
    sudo sysctl net.ipv4.ip_forward=0 > /dev/null
    
    notify "✅ Reverse tethering stopped securely. Network restrictions cleared."
    exit 0
fi

notify "🔄 Initializing USB Tethering Engine..."

# 2. auto-ADB Trigger: Force RNDIS mode without touching the phone screen (Rooted Only)
if command -v adb_wrapper >/dev/null 2>&1; then
    DEVICES=($(adb_wrapper devices | grep -E "\bdevice$" | awk '{print $1}'))
    if [ ${#DEVICES[@]} -gt 0 ]; then
        for DEV in "${DEVICES[@]}"; do
            # Only force RNDIS if the device has root capabilities to avoid severing ADB for Gnirehtet
            if adb_wrapper -s "$DEV" shell su -c id 2>/dev/null | grep -q "uid=0"; then
                echo "📱 Forcing RNDIS mode via ADB on $DEV..."
                adb_wrapper -s "$DEV" shell svc usb setFunctions rndis
            else
                echo "📱 Device $DEV is unrooted. Skipping RNDIS force to preserve ADB for Gnirehtet."
            fi
        done
        sleep 3 # Wait for the Linux kernel to recognize possible new USB network interfaces
    fi
else
    notify "❌ ADB is not installed. Zero-touch automation will not work."
fi

# 3. Detect USB Interfaces (handles multiple phones connected at once)
USB_IFACES=$(ip link show | awk -F: '$0 !~ "lo|vir|wl|^[^0-9]"{print $2;getline}' | grep -E "usb|enp.*u.*|rndis|enx" | tr -d ' ')

# 4. Enable Kernel Routing & flush old rules
sudo sysctl net.ipv4.ip_forward=1 > /dev/null
sudo iptables -F
sudo iptables -t nat -F
sudo iptables -t nat -A POSTROUTING -o "$HOST_IFACE" -j MASQUERADE

# 5 & 6. Configure Interfaces, Android Route, and Gnirehtet Smart Fallback
SUBNET=42
USB_ARRAY=($USB_IFACES)

for ((i=0; i<${#DEVICES[@]}; i++)); do
    DEV="${DEVICES[$i]}"
    
    IFACE=""
    if [ $i -lt ${#USB_ARRAY[@]} ]; then
        IFACE="${USB_ARRAY[$i]}"
    fi

    echo "🌐 Configuring network for Android Device: $DEV..."
    
    # Check if native IP routing is allowed by the Android OS
    adb_wrapper -s "$DEV" shell "ip addr flush dev rndis0" 2>/dev/null
    adb_wrapper -s "$DEV" shell "ip addr add 192.168.${SUBNET}.2/24 dev rndis0" 2>/dev/null
    adb_wrapper -s "$DEV" shell "ip link set rndis0 up" 2>/dev/null
    
    # Attempt to add the default route and capture errors
    ROUTE_OUT=$(adb_wrapper -s "$DEV" shell "ip route add default via 192.168.${SUBNET}.1 dev rndis0" 2>&1)
    
    if echo "$ROUTE_OUT" | grep -qi "Permission denied"; then
        echo "⚠️ Knox/Root restriction detected on $DEV. Booting Gnirehtet fallback..."
        notify "⚠️ Knox/Root restriction detected. Booting Gnirehtet..."
        
        # Setup gnirehtet if missing
        if [ ! -f "$GNIREHTET_DIR/gnirehtet" ]; then
            notify "⬇️ Downloading Gnirehtet Engine..."
            mkdir -p "$GNIREHTET_DIR"
            wget -qO /tmp/gnh.zip https://github.com/Genymobile/gnirehtet/releases/download/v2.5.1/gnirehtet-rust-linux64-v2.5.1.zip
            unzip -q -o /tmp/gnh.zip -d /tmp/gnh_ext
            mv /tmp/gnh_ext/gnirehtet-rust-linux64/* "$GNIREHTET_DIR/"
            rm -rf /tmp/gnh.zip /tmp/gnh_ext
        fi
        
        # Launch gnirehtet in true background isolation for this device
        sudo -u "${SUDO_USER:-$USER}" nohup "$GNIREHTET_DIR/gnirehtet" run "$DEV" "$DNS_1" >/dev/null 2>&1 &
        
        # Inject DNS into system properties to force stubborn apps (DownloadManager, Play Store) to resolve through the VPN
        adb_wrapper -s "$DEV" shell "setprop net.dns1 $DNS_1" 2>/dev/null
        adb_wrapper -s "$DEV" shell "setprop net.dns2 $DNS_2" 2>/dev/null
        
        notify "🚀 Gnirehtet VPN Active! Tap 'OK' on your phone to connect."
    else
        # Native Routing succeeded! Proceed with iptables bridge.
        if [ -n "$IFACE" ]; then
            echo "🔗 Configuring Native iptables bridge for $IFACE (192.168.${SUBNET}.1)..."
            sudo iptables -A FORWARD -i "$IFACE" -o "$HOST_IFACE" -j ACCEPT
            sudo iptables -A FORWARD -i "$HOST_IFACE" -o "$IFACE" -m state --state RELATED,ESTABLISHED -j ACCEPT
            
            sudo ip addr flush dev "$IFACE"
            sudo ip addr add 192.168.${SUBNET}.1/24 dev "$IFACE"
            sudo ip link set "$IFACE" up
            
            # DNS configuration
            adb_wrapper -s "$DEV" shell "setprop net.dns1 $DNS_1" 2>/dev/null
            adb_wrapper -s "$DEV" shell "ndc resolver setnetdns rndis0 \"\" $DNS_1 $DNS_2" 2>/dev/null
            
            notify "🎉 Native Tethering Bridge Active for $DEV!"
        fi
    fi

    SUBNET=$((SUBNET + 1))
done

if [ ${#DEVICES[@]} -eq 0 ]; then
    notify "❌ No ADB devices detected. Plug in your phone and enable USB Debugging."
fi

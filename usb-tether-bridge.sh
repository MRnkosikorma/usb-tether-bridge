#!/bin/bash

# =========================================================================
# Android USB Reverse Tethering Script V2.0 (Linux)
# Features: ADB Auto-Trigger, Notifications, DNS Injection, Multi-Device
# Usage: ./usb-tether-bridge.sh [start|stop]
# Author: Nkosilathi Koma
# =========================================================================

ACTION=${1:-start}

# 💬 Function: Native Linux Desktop Notifications
notify() {
    sudo -u $SUDO_USER notify-send "USB Tether Bridge" "$1" --icon=network-transmit-receive -t 5000 2>/dev/null || echo "💬 $1"
}

# 1. Detect active PC interface (Wi-Fi or Ethernet)
HOST_IFACE=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $5}')
if [ -z "$HOST_IFACE" ]; then
    notify "❌ Could not detect PC internet connection."
    exit 1
fi

# 🛑 STOP MODE: Clean up Routing and Firewall
if [ "$ACTION" == "stop" ]; then
    echo "🛑 Stopping tethering and cleaning up..."
    sudo iptables -F
    sudo iptables -t nat -F
    sudo sysctl net.ipv4.ip_forward=0 > /dev/null
    notify "✅ Reverse tethering stopped securely. Network restrictions cleared."
    exit 0
fi

notify "🔄 Initializing USB Tethering..."

# 2. auto-ADB Trigger: Force RNDIS mode without touching the phone screen
if command -v adb >/dev/null 2>&1; then
    DEVICES=$(adb devices | grep -E "\bdevice$" | awk '{print $1}')
    if [ -n "$DEVICES" ]; then
        for DEV in $DEVICES; do
            echo "📱 Forcing RNDIS mode via ADB on $DEV..."
            adb -s $DEV shell svc usb setFunctions rndis
        done
        sleep 3 # Wait 3 seconds for the Linux kernel to recognize the new USB network interface
    fi
fi

# 3. Detect USB Interfaces (handles multiple phones connected at once)
USB_IFACES=$(ip link show | awk -F: '$0 !~ "lo|vir|wl|^[^0-9]"{print $2;getline}' | grep -E "usb|enp.*u.*c|rndis" | tr -d ' ')
if [ -z "$USB_IFACES" ]; then
    notify "❌ No USB network interface detected. Ensure phone is connected."
    exit 1
fi

echo "✅ Routing internet from $HOST_IFACE to USB devices..."

# 4. Enable Kernel Routing & flush old rules
sudo sysctl net.ipv4.ip_forward=1 > /dev/null
sudo iptables -F
sudo iptables -t nat -F
sudo iptables -t nat -A POSTROUTING -o "$HOST_IFACE" -j MASQUERADE

# 5. Loop through devices to assign IP and NAT for multi-device support
SUBNET=42
for IFACE in $USB_IFACES; do
    echo "🔗 Configuring bridge for $IFACE (192.168.${SUBNET}.1)..."
    sudo iptables -A FORWARD -i "$IFACE" -o "$HOST_IFACE" -j ACCEPT
    sudo iptables -A FORWARD -i "$HOST_IFACE" -o "$IFACE" -m state --state RELATED,ESTABLISHED -j ACCEPT
    
    sudo ip addr flush dev "$IFACE"
    sudo ip addr add 192.168.${SUBNET}.1/24 dev "$IFACE"
    sudo ip link set "$IFACE" up
    
    SUBNET=$((SUBNET + 1))
done

# 6. DNS Setup via ADB (forces the phone to actually use the PC connection)
if command -v adb >/dev/null 2>&1; then
    DEVICES=$(adb devices | grep -E "\bdevice$" | awk '{print $1}')
    for DEV in $DEVICES; do
        echo "🌐 Injecting DNS (8.8.8.8) into $DEV..."
        # Legacy injection for older Androids
        adb -s $DEV shell "setprop net.dns1 8.8.8.8" 2>/dev/null
        # ndc routing for modern Androids (forces traffic via rndis0/usb0 proxy)
        adb -s $DEV shell "ndc resolver setnetdns rndis0 $(local ip addr show $IFACE) 8.8.8.8 8.8.4.4" 2>/dev/null
    done
fi

notify "🎉 Success! Internet is now successfully piped to your USB devices."

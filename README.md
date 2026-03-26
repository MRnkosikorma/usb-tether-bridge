# USB Tether Bridge (Linux to Android)

A complete, automated shell utility that routes a Linux PC's active internet connection (Wi-Fi/Ethernet) to any connected Android device via USB (Reverse Tethering).

![USB Tether Bridge](https://img.shields.io/badge/Platform-Linux-blue) ![License](https://img.shields.io/badge/License-MIT-green) ![Shell](https://img.shields.io/badge/Language-Bash-orange)

## Features
- **Zero-Touch Android Setup:** Uses `adb` to automatically force the connected phone into RNDIS/USB-Tethering mode without ever having to touch the phone's screen.
- **Native Desktop Integration:** Comes with a ready-to-use `.desktop` graphical shortcut that uses `pkexec` for seamless GUI password entry (no messy terminals).
- **DNS Injection:** Actively commands the Android device to route DNS queries to Google DNS (`8.8.8.8`) via `ndc`, preventing "Connected, no internet" errors on strict apps.
- **Multi-Device Support:** Loops through and bridges every connected USB device simultaneously.
- **Clean "Stop" Routine:** Right-click the desktop shortcut to select **"Stop Tethering,"** which safely flushes `iptables` routing, removes NAT masquerading, and disables kernel IPv4 forwarding.
- **Graphical Notifications:** Replaces terminal spam with sleek, native Linux desktop notifications via `notify-send`.

---

## 🚀 Installation & Usage

1. **Clone the repository:**
   ```bash
   git clone https://github.com/YOUR_GITHUB_USERNAME/usb-tether-bridge.git
   cd usb-tether-bridge
   ```

2. **Deploy to your Desktop:**
   Move the script and the branded shortcut to your Desktop, make them executable, and trust the launcher:
   ```bash
   cp usb-tether-bridge.sh ~/Desktop/
   cp usb-tether-bridge.desktop ~/Desktop/
   chmod +x ~/Desktop/usb-tether-bridge.sh ~/Desktop/usb-tether-bridge.desktop
   gio set ~/Desktop/usb-tether-bridge.desktop metadata::trusted yes 2>/dev/null
   ```

3. **Run it:**
   Simply double-click the **USB Tether Bridge** icon on your Desktop. It will prompt for your administrator password natively, enable routing, and notify you when the bridge is active.

4. **Stop it:**
   Right-click the desktop icon and click **"Stop Tethering (Clean Rules)"**.

---

## 🔧 Under the Hood (How it Works)
1. Detects the host PC's outbound interface (`ip route get 8.8.8.8`).
2. Polls `adb devices` to trigger `svc usb setFunctions rndis` on the phone.
3. Detects the newly mounted USB Ethernet interface (`usb0`, `rndis0`, or `enp*`).
4. Flips `net.ipv4.ip_forward=1` in the system kernel.
5. Configures `iptables` rules to `MASQUERADE` and `FORWARD` packets across the bridge.
6. Assigns `192.168.x.1` gateways iteratively to every connected USB interface.

## Requirements
- Any Linux Distribution (Ubuntu/Debian, Fedora, Arch)
- `iptables` & `iproute2` (Standard on almost all distros)
- `adb` (Optional, but required for the "Zero-Touch" automation feature)
- `polkit` / `pkexec` (For the graphical password prompt)

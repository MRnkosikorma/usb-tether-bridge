# USB Tether Bridge 3.0 (Linux to Android)

A competitive, highly-automated, and universal utility that routes a Linux PC's active internet connection (Wi-Fi/Ethernet) directly into any connected Android device via USB (Reverse Tethering).

![USB Tether Bridge](https://img.shields.io/badge/Platform-Linux-blue) ![License](https://img.shields.io/badge/License-MIT-green) ![Status](https://img.shields.io/badge/Status-V3.0_Stable-success)

## 🌟 What makes V3.0 the best?
Standard `iptables` tethering scripts fail on modern, unrooted, or Knox-secured Android devices. **USB Tether Bridge 3.0** completely solves this by introducing a **Smart Detection Engine** alongside true Linux Desktop integration.

### 🔥 V3.0 Features:
1. **Automatic Gnirehtet Smart-Fallback:** The script intelligently detects if your phone blocks native IP routing commands. If it does (e.g., Unrooted Samsung Galaxy), the script silently downloads Genymobile's `gnirehtet` Rust engine and securely relays your internet via a localized VPN tunnel without needing Root!
2. **True Plug-and-Play (Udev Integration):** Forget clicking buttons. Thanks to the integrated `udev` rules, the moment you plug your phone into the PC, the Linux kernel automatically triggers the background service and routes the internet instantly.
3. **Python System Tray Applet:** Includes a sleek, persistent desktop GUI written in Python (`pystray`). Control the bridge, track status, and open settings straight from your system tray.
4. **Custom DNS Overrides:** Bypass your ISP's DNS by defining your own custom DNS resolvers (e.g., Cloudflare `1.1.1.1` or Google `8.8.8.8`) securely in the `~/.config/usb-tether-bridge/config.env` file.
5. **Zero-Touch RNDIS & Automated ADB:** Forces the phone into USB Tethering mode without touching the screen.

---

## 🚀 Installation

We have included a powerful setup module to handle all dependencies automatically.

1. **Clone the repository:**
   ```bash
   git clone https://github.com/MRnkosikorma/usb-tether-bridge.git
   cd usb-tether-bridge
   ```

2. **Run the Automated Installer:**
   ```bash
   chmod +x install.sh
   ./install.sh
   ```
   **What the installer does:**
   - Creates a dedicated Python Virtual Environment for the GUI.
   - Installs the `systemd` background service (`usb-tether-bridge.service`).
   - Registers the `udev` rule (`99-usb-tether.rules`) for pure plug-and-play functionality.
   - Sets the Python app to launch automatically on Desktop login.

---

## 🔧 Usage Details

### Plug-and-Play mode
Simply plug an Android phone into your computer with USB Debugging enabled. The PC will detect the phone and instantly beam internet into it. A notification will appear on your desktop when the tether is active.

*(If your phone is unrooted and triggers the Gnirehtet fallback, a prompt will appear on your phone saying "Connection request." Tap **OK**.)*

### Manual GUI Mode
If you prefer manual control, use the **USB Tether Bridge** system tray icon!
- **Start Bridge**: Manually trigger routing.
- **Stop Bridge**: Kills all gnirehtet relays, flushes `iptables` NAT routing, and gracefully ends the session.
- **Settings (DNS)**: Opens your local config file to change DNS resolvers.

---

## 👨‍💻 Credits & License

**Creator:** Nkosilathi Koma

This project leverages the incredible [Genymobile/gnirehtet](https://github.com/Genymobile/gnirehtet) engine to support completely unrooted Android workflows.

Released open-source under the **MIT License**.

# USB Tether Bridge 3.0 (Linux ➔ Android)

A brilliantly simple, plug-and-play tool that shares your Linux PC's internet connection with any Android phone over a USB cable. 

![Linux](https://img.shields.io/badge/Platform-Linux-blue) ![License](https://img.shields.io/badge/License-MIT-green) ![Status](https://img.shields.io/badge/Status-V3.0_Stable-success)

## ⚡ How to get started

1. **Download the tool:**
   ```bash
   git clone https://github.com/MRnkosikorma/usb-tether-bridge.git
   cd usb-tether-bridge
   ```

2. **Run the One-Click Installer:**
   ```bash
   chmod +x install.sh
   ./install.sh
   ```
*(That's it! The installer permanently sets up all background services, Python environments, and Auto-Detect rules for you).*

---

## 📱 How to actually use it

There are two ways to use your new tether bridge:

### Method 1: The Magic "Plug-and-Play" (Recommended)
1. Turn on **USB Debugging** in your Android's Developer Options.
2. **Plug your phone into your PC.**
3. The PC will instantly detect the phone, start the bridging service in the background, and a VPN prompt will appear on your phone screen.
4. Tap **OK** on your phone. *You are now connected!*

### Method 2: The Graphical Menu (Manual Control)
If you prefer buttons, the installer added a **USB Tether Bridge** icon to your Linux system tray (near your clock/Wi-Fi). 
Right-click it to:
- **Start Bridge**
- **Stop Bridge** (Cleanly kills the connection and Android VPN)
- **Settings** (Change your custom DNS)

---

## 💡 Troubleshooting: "Stubborn Apps won't download!"
Because strict unrooted devices (like Samsung Knox) use a background VPN relay instead of a native network, some apps (like the **Google Play Store** or **WhatsApp Backups**) might say *"Waiting for Wi-Fi"* and refuse to download large files.

**The Fix is extremely simple:**
1. Turn on your phone's **Wi-Fi** or **Mobile Data** (It does not need to actually have internet).
2. Because the antenna is "On", the stubborn apps are tricked into thinking they are on a normal connection.
3. The background USB Tether Bridge intercepts 100% of the traffic before it ever hits the antenna, routing it flawlessly back through your USB cable for free!

This guarantees that every single app on your phone can utilize the connection.

---

**Credits:** Created by Nkosilathi Koma. Powered by the [Genymobile/gnirehtet](https://github.com/Genymobile/gnirehtet) relay engine for unrooted Android support.

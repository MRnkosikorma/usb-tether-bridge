#!/bin/bash

# =========================================================================
# USB Tether Bridge 3.0 Installer
# Sets up Udev rules, Systemd Services, and the Python GUI environment.
# =========================================================================

echo "🚀 Starting USB Tether Bridge Installation..."

# 1. Ask for sudo permissions early
sudo -v

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
BIN_DIR="$HOME/.local/share/usb-tether-bridge"
VENV_DIR="$BIN_DIR/venv"

echo "📦 Setting up Python Virtual Environment in $VENV_DIR..."
mkdir -p "$BIN_DIR"
python3 -m venv "$VENV_DIR"
"$VENV_DIR/bin/pip" install --quiet --upgrade pip
"$VENV_DIR/bin/pip" install --quiet pystray Pillow

echo "⚙️ Creating Systemd Service for seamless background routing..."
cat <<EOF | sudo tee /etc/systemd/system/usb-tether-bridge.service > /dev/null
[Unit]
Description=USB Tether Bridge Network Router
After=network.target

[Service]
Type=oneshot
ExecStart=$APP_DIR/usb-tether-bridge.sh start
ExecStop=$APP_DIR/usb-tether-bridge.sh stop
RemainAfterExit=yes
User=root
Environment="SUDO_USER=$USER"

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload

echo "🔌 Creating Udev Rules for Auto-Detect & Auto-Teardown (Plug-and-Play)..."
cat <<EOF | sudo tee /etc/udev/rules.d/99-usb-tether.rules > /dev/null
# Trigger the usb-tether-bridge service when an Android device with ADB (ff4201) connects
ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ENV{ID_USB_INTERFACES}=="*:ff4201:*", TAG+="systemd", ENV{SYSTEMD_WANTS}="usb-tether-bridge.service"

# Destroy the connection and fallback when the device disconnects
ACTION=="remove", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ENV{ID_USB_INTERFACES}=="*:ff4201:*", RUN+="/usr/bin/systemctl stop usb-tether-bridge.service"
EOF

sudo udevadm control --reload-rules
sudo udevadm trigger

echo "🖥️ Setting up Auto-Start Desktop GUI..."
AUTOSTART_DIR="$HOME/.config/autostart"
mkdir -p "$AUTOSTART_DIR"

cat <<EOF > "$AUTOSTART_DIR/usb-tether-tray.desktop"
[Desktop Entry]
Name=USB Tether Bridge
Exec=$VENV_DIR/bin/python $APP_DIR/usb-tether-tray.py
Icon=network-transmit-receive
Type=Application
Categories=Network;
X-GNOME-Autostart-enabled=true
EOF

chmod +x "$APP_DIR/usb-tether-bridge.sh"
chmod +x "$APP_DIR/usb-tether-tray.py"
chmod +x "$APP_DIR/install.sh"
gio set "$AUTOSTART_DIR/usb-tether-tray.desktop" metadata::trusted yes 2>/dev/null

echo "✅ Installation Complete!"
echo "The System Tray icon will seamlessly load on your next login, or you can run it now in the background:"
echo "$VENV_DIR/bin/python $APP_DIR/usb-tether-tray.py &"

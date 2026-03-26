#!/usr/bin/env python3

import os
import subprocess
import threading
import time
from pystray import Icon, Menu, MenuItem
from PIL import Image, ImageDraw

# Status tracking
is_active = False

def create_icon(active=False):
    """Generate a simple blue or green networking icon dynamically."""
    image = Image.new('RGB', (64, 64), color=(30, 30, 30))
    dc = ImageDraw.Draw(image)
    color = (0, 200, 0) if active else (50, 150, 255)
    dc.rectangle((16, 16, 48, 48), fill=color)
    dc.rectangle((24, 24, 40, 40), fill=(255, 255, 255))
    return image

def run_command_in_background(cmd):
    """Run a command asynchronously to prevent blocking the GUI loop."""
    def worker():
        try:
            # systemctl will natively trigger a graphical Polkit password prompt on Linux desktops
            subprocess.run(cmd, check=True)
        except subprocess.CalledProcessError as e:
            print(f"Error executing {cmd}: {e}")
    threading.Thread(target=worker, daemon=True).start()

def on_start(icon, item):
    """Trigger the tether bridge start via systemd."""
    cmd = ["systemctl", "start", "usb-tether-bridge.service"]
    run_command_in_background(cmd)

def on_stop(icon, item):
    """Trigger the tether bridge stop via systemd."""
    cmd = ["systemctl", "stop", "usb-tether-bridge.service"]
    run_command_in_background(cmd)

def on_settings(icon, item):
    """Open the DNS configuration file."""
    config_dir = os.path.expanduser("~/.config/usb-tether-bridge")
    config_file = os.path.join(config_dir, "config.env")
    
    if not os.path.exists(config_file):
        os.makedirs(config_dir, exist_ok=True)
        with open(config_file, "w") as f:
            f.write("DNS_1=8.8.8.8\nDNS_2=1.1.1.1\n")
            
    run_command_in_background(["xdg-open", config_file])

def check_status_loop(icon):
    """Periodically check if the service is running and update the icon."""
    global is_active
    while True:
        try:
            result = subprocess.run(["systemctl", "is-active", "usb-tether-bridge.service"], 
                                    stdout=subprocess.PIPE, text=True)
            current_active = (result.stdout.strip() == "active")
        except Exception:
            current_active = False

        if current_active != is_active:
            is_active = current_active
            icon.icon = create_icon(is_active)
            # Re-render the menu items
            icon.update_menu()
            
        time.sleep(2)

def status_text(icon):
    return "Status: ACTIVE (Connected)" if is_active else "Status: INACTIVE (Standby)"

def on_quit(icon, item):
    icon.stop()

def main():
    menu = Menu(
        MenuItem(status_text, None, enabled=False),
        Menu.SEPARATOR,
        MenuItem('Start Bridge', on_start),
        MenuItem('Stop Bridge', on_stop),
        Menu.SEPARATOR,
        MenuItem('Settings (DNS)', on_settings),
        Menu.SEPARATOR,
        MenuItem('Quit', on_quit)
    )

    icon = Icon("usb-tether-bridge", create_icon(False), "USB Tether Bridge", menu)
    
    # Start status monitoring in background
    threading.Thread(target=check_status_loop, args=(icon,), daemon=True).start()
    
    icon.run()

if __name__ == "__main__":
    main()

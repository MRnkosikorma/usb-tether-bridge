#!/usr/bin/env python3

import os
import subprocess
import threading
from pystray import Icon, Menu, MenuItem
from PIL import Image, ImageDraw

SCRIPT_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "usb-tether-bridge.sh")

def create_icon():
    """Generate a simple blue networking icon dynamically."""
    image = Image.new('RGB', (64, 64), color=(30, 30, 30))
    dc = ImageDraw.Draw(image)
    dc.rectangle((16, 16, 48, 48), fill=(0, 150, 255))
    dc.rectangle((24, 24, 40, 40), fill=(255, 255, 255))
    return image

def run_command_in_background(cmd):
    """Run a command asynchronously to prevent blocking the GUI loop."""
    def worker():
        try:
            subprocess.run(cmd, check=True)
        except subprocess.CalledProcessError as e:
            print(f"Error executing {cmd}: {e}")
    threading.Thread(target=worker, daemon=True).start()

def on_start(icon, item):
    """Trigger the tether bridge start via pkexec for graphical auth."""
    cmd = ["pkexec", SCRIPT_PATH, "start"]
    run_command_in_background(cmd)

def on_stop(icon, item):
    """Trigger the tether bridge stop."""
    cmd = ["pkexec", SCRIPT_PATH, "stop"]
    run_command_in_background(cmd)

def on_settings(icon, item):
    """Open the DNS configuration file."""
    config_dir = os.path.expanduser("~/.config/usb-tether-bridge")
    config_file = os.path.join(config_dir, "config.env")
    
    if not os.path.exists(config_file):
        os.makedirs(config_dir, exist_ok=True)
        with open(config_file, "w") as f:
            f.write("DNS_1=8.8.8.8\nDNS_2=1.1.1.1\n")
            
    # Open with default text editor
    run_command_in_background(["xdg-open", config_file])

def on_quit(icon, item):
    icon.stop()

def main():
    if not os.path.exists(SCRIPT_PATH):
        print(f"Error: Could not find {SCRIPT_PATH}")
        return

    menu = Menu(
        MenuItem('Start Bridge', on_start),
        MenuItem('Stop Bridge', on_stop),
        Menu.SEPARATOR,
        MenuItem('Settings (DNS)', on_settings),
        Menu.SEPARATOR,
        MenuItem('Quit', on_quit)
    )

    icon = Icon("usb-tether-bridge", create_icon(), "USB Tether Bridge", menu)
    icon.run()

if __name__ == "__main__":
    main()

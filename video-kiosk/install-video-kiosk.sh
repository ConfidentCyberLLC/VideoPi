#!/bin/bash

# Installation script for Video Kiosk systemd service

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Video Kiosk Service Installer ===${NC}\n"

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}ERROR: Do not run this script as root/sudo${NC}"
    echo "Run it as your normal user. It will prompt for sudo when needed."
    exit 1
fi

# Check if mpv is installed
if ! command -v mpv &> /dev/null; then
    echo -e "${RED}ERROR: mpv is not installed${NC}"
    echo ""
    echo "Please install mpv first:"
    echo "  Ubuntu/Debian: sudo apt-get install mpv"
    echo "  Fedora:        sudo dnf install mpv"
    echo "  Arch:          sudo pacman -S mpv"
    exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Prompt for video file path
echo -e "${YELLOW}Enter the full path to your video file:${NC}"
read -e -p "Video path: " VIDEO_PATH

# Expand tilde to home directory if present
VIDEO_PATH="${VIDEO_PATH/#\~/$HOME}"

# Check if video file exists
if [ ! -f "$VIDEO_PATH" ]; then
    echo -e "${RED}ERROR: Video file not found: $VIDEO_PATH${NC}"
    exit 1
fi

echo -e "${GREEN}Video file found: $VIDEO_PATH${NC}"

# Detect display
if [ -z "$DISPLAY" ]; then
    DISPLAY_NUM=":0"
    echo -e "${YELLOW}DISPLAY not set, using default: :0${NC}"
else
    DISPLAY_NUM="$DISPLAY"
    echo -e "${GREEN}Using DISPLAY: $DISPLAY_NUM${NC}"
fi

# Get X authority file
if [ -f "$HOME/.Xauthority" ]; then
    XAUTH_FILE="$HOME/.Xauthority"
elif [ -f "/run/user/$(id -u)/gdm/Xauthority" ]; then
    XAUTH_FILE="/run/user/$(id -u)/gdm/Xauthority"
else
    XAUTH_FILE="$HOME/.Xauthority"
    echo -e "${YELLOW}Warning: Could not find .Xauthority, using default path${NC}"
fi

# Ask about keyboard controls
echo ""
echo -e "${YELLOW}Do you want to disable keyboard controls?${NC}"
echo "If disabled, you won't be able to quit with 'q' or use other mpv keys"
read -p "(y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    DISABLE_INPUT="--no-input-default-bindings"
else
    DISABLE_INPUT=""
fi

# Create service file
SERVICE_FILE="/tmp/video-kiosk.service"

echo -e "${GREEN}Creating service file...${NC}"

cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Auto-play Video in Kiosk Mode
After=graphical.target
Wants=graphical.target

[Service]
Type=simple
User=$USER
Group=$USER

# Set display
Environment=DISPLAY=$DISPLAY_NUM
Environment=XAUTHORITY=$XAUTH_FILE

# Wait for X server to be ready
ExecStartPre=/bin/sleep 5

# Play video with mpv
ExecStart=/usr/bin/mpv \\
    --fs \\
    --no-audio \\
    --no-osc \\
    --no-osd-bar \\
    --osd-level=0 \\
    --loop \\
    --no-border \\
    --no-keepaspect-window \\
    --hwdec=auto \\
    $DISABLE_INPUT \\
    "$VIDEO_PATH"

# Restart if it crashes
Restart=always
RestartSec=3

# Standard output to journal
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=graphical.target
EOF

# Install service file
echo -e "${GREEN}Installing systemd service...${NC}"
sudo cp "$SERVICE_FILE" /etc/systemd/system/video-kiosk.service

# Reload systemd
echo -e "${GREEN}Reloading systemd daemon...${NC}"
sudo systemctl daemon-reload

# Enable the service
echo -e "${GREEN}Enabling service to start on boot...${NC}"
sudo systemctl enable video-kiosk.service

# Ask if user wants to start now
echo ""
echo -e "${YELLOW}Do you want to start the video now?${NC}"
read -p "(y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}Starting video kiosk service...${NC}"
    sudo systemctl start video-kiosk.service
    sleep 2
    echo -e "${GREEN}Video should now be playing!${NC}"
fi

# Clean up
rm "$SERVICE_FILE"

echo -e "\n${GREEN}=== Installation Complete! ===${NC}\n"

echo "Service installed successfully!"
echo ""
echo "Useful commands:"
echo -e "  ${YELLOW}Check status:${NC}        sudo systemctl status video-kiosk"
echo -e "  ${YELLOW}Start video:${NC}         sudo systemctl start video-kiosk"
echo -e "  ${YELLOW}Stop video:${NC}          sudo systemctl stop video-kiosk"
echo -e "  ${YELLOW}View logs:${NC}           sudo journalctl -u video-kiosk -f"
echo -e "  ${YELLOW}Disable autostart:${NC}   sudo systemctl disable video-kiosk"
echo ""
if [[ ! $DISABLE_INPUT =~ "--no-input-default-bindings" ]]; then
    echo -e "${BLUE}Keyboard shortcuts (when video is focused):${NC}"
    echo "  q - Quit video player"
    echo "  f - Toggle fullscreen"
    echo "  Space - Pause/Resume"
fi
echo ""
echo -e "${BLUE}The video will automatically start on every boot.${NC}"

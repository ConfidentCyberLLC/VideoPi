#!/bin/bash

# Installation script for NAS Video Sync systemd service and timer

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== NAS Video Sync Service Installer ===${NC}\n"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}ERROR: Do not run this script as root/sudo${NC}"
    echo "Run it as your normal user. It will prompt for sudo when needed."
    exit 1
fi

# Check if config file exists
if [ ! -f "$SCRIPT_DIR/sync_nas_video.conf" ]; then
    echo -e "${YELLOW}WARNING: Configuration file not found!${NC}"
    echo "Please create sync_nas_video.conf from sync_nas_video.conf.example"
    echo ""
    read -p "Do you want to continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if script exists and is executable
if [ ! -f "$SCRIPT_DIR/sync_nas_video.sh" ]; then
    echo -e "${RED}ERROR: sync_nas_video.sh not found in $SCRIPT_DIR${NC}"
    exit 1
fi

if [ ! -x "$SCRIPT_DIR/sync_nas_video.sh" ]; then
    echo -e "${YELLOW}Making sync_nas_video.sh executable...${NC}"
    chmod +x "$SCRIPT_DIR/sync_nas_video.sh"
fi

# Create temporary service file with correct paths
SERVICE_FILE="/tmp/nas-video-sync.service"
TIMER_FILE="/tmp/nas-video-sync.timer"

echo -e "${GREEN}Creating service file with correct paths...${NC}"

cat > "$SERVICE_FILE" << EOF
[Unit]
Description=NAS Video Sync Service
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
User=$USER
Group=$USER

# Set working directory to where the script is located
WorkingDirectory=$SCRIPT_DIR

# Source the configuration file and run the script
ExecStart=/bin/bash -c 'source $SCRIPT_DIR/sync_nas_video.conf && $SCRIPT_DIR/sync_nas_video.sh'

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=nas-video-sync

# Security hardening
PrivateTmp=yes
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

echo -e "${GREEN}Creating timer file...${NC}"

cp "$SCRIPT_DIR/nas-video-sync.timer" "$TIMER_FILE"

# Install service and timer files
echo -e "${GREEN}Installing systemd service and timer...${NC}"
sudo cp "$SERVICE_FILE" /etc/systemd/system/nas-video-sync.service
sudo cp "$TIMER_FILE" /etc/systemd/system/nas-video-sync.timer

# Reload systemd
echo -e "${GREEN}Reloading systemd daemon...${NC}"
sudo systemctl daemon-reload

# Enable and start the timer
echo -e "${GREEN}Enabling timer...${NC}"
sudo systemctl enable nas-video-sync.timer

echo -e "${GREEN}Starting timer...${NC}"
sudo systemctl start nas-video-sync.timer

# Clean up
rm "$SERVICE_FILE" "$TIMER_FILE"

echo -e "\n${GREEN}=== Installation Complete! ===${NC}\n"

echo "Service installed and timer started successfully!"
echo ""
echo "Useful commands:"
echo -e "  ${YELLOW}Check timer status:${NC}       sudo systemctl status nas-video-sync.timer"
echo -e "  ${YELLOW}Check service status:${NC}     sudo systemctl status nas-video-sync.service"
echo -e "  ${YELLOW}View logs:${NC}                sudo journalctl -u nas-video-sync -f"
echo -e "  ${YELLOW}Run manually now:${NC}         sudo systemctl start nas-video-sync.service"
echo -e "  ${YELLOW}List all timers:${NC}          systemctl list-timers"
echo -e "  ${YELLOW}Disable timer:${NC}            sudo systemctl disable nas-video-sync.timer"
echo -e "  ${YELLOW}Stop timer:${NC}               sudo systemctl stop nas-video-sync.timer"
echo ""
echo -e "${BLUE}The service will run every 24 hours starting from now.${NC}"
echo -e "${BLUE}Next run: $(systemctl status nas-video-sync.timer | grep Trigger | awk '{print $2, $3, $4}')${NC}"

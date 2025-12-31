#!/bin/bash

# Uninstallation script for NAS Video Sync systemd service and timer

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== NAS Video Sync Service Uninstaller ===${NC}\n"

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}ERROR: Do not run this script as root/sudo${NC}"
    echo "Run it as your normal user. It will prompt for sudo when needed."
    exit 1
fi

# Confirm uninstallation
echo -e "${YELLOW}This will remove the NAS Video Sync systemd service and timer.${NC}"
echo -e "${YELLOW}Your script files and configuration will NOT be deleted.${NC}"
echo ""
read -p "Are you sure you want to continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstallation cancelled."
    exit 0
fi

# Stop the timer
echo -e "${GREEN}Stopping timer...${NC}"
sudo systemctl stop nas-video-sync.timer 2>/dev/null || true

# Disable the timer
echo -e "${GREEN}Disabling timer...${NC}"
sudo systemctl disable nas-video-sync.timer 2>/dev/null || true

# Remove service and timer files
echo -e "${GREEN}Removing systemd files...${NC}"
sudo rm -f /etc/systemd/system/nas-video-sync.service
sudo rm -f /etc/systemd/system/nas-video-sync.timer

# Reload systemd
echo -e "${GREEN}Reloading systemd daemon...${NC}"
sudo systemctl daemon-reload
sudo systemctl reset-failed 2>/dev/null || true

echo -e "\n${GREEN}=== Uninstallation Complete! ===${NC}\n"
echo "The systemd service and timer have been removed."
echo "Your script files in $(pwd) have been preserved."

#!/bin/bash

# Uninstallation script for Video Kiosk systemd service

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Video Kiosk Service Uninstaller ===${NC}\n"

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}ERROR: Do not run this script as root/sudo${NC}"
    echo "Run it as your normal user. It will prompt for sudo when needed."
    exit 1
fi

# Confirm uninstallation
echo -e "${YELLOW}This will remove the Video Kiosk systemd service.${NC}"
echo ""
read -p "Are you sure you want to continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstallation cancelled."
    exit 0
fi

# Stop the service
echo -e "${GREEN}Stopping service...${NC}"
sudo systemctl stop video-kiosk.service 2>/dev/null || true

# Disable the service
echo -e "${GREEN}Disabling service...${NC}"
sudo systemctl disable video-kiosk.service 2>/dev/null || true

# Remove service file
echo -e "${GREEN}Removing systemd service file...${NC}"
sudo rm -f /etc/systemd/system/video-kiosk.service

# Reload systemd
echo -e "${GREEN}Reloading systemd daemon...${NC}"
sudo systemctl daemon-reload
sudo systemctl reset-failed 2>/dev/null || true

echo -e "\n${GREEN}=== Uninstallation Complete! ===${NC}\n"
echo "The video kiosk service has been removed."
echo "The video will no longer auto-play on boot."

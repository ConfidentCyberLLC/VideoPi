#!/bin/bash

# NAS Video Sync Script
# Compares MD5 hash of video on NAS with local copy
# If different, backs up local file and copies new version from NAS

set -e

# Configuration - modify these variables
NAS_USER="${NAS_USER:-your_username}"
NAS_PASSWORD="${NAS_PASSWORD:-your_password}"
NAS_HOST="${NAS_HOST:-192.168.1.100}"
NAS_SHARE="${NAS_SHARE:-videos}"
MOUNT_POINT="${MOUNT_POINT:-/mnt/nas}"
NAS_VIDEO_PATH="${NAS_VIDEO_PATH:-/path/to/video.mp4}"  # Path relative to NAS share
LOCAL_VIDEO_PATH="${LOCAL_VIDEO_PATH:-/path/to/local/video.mp4}"
SMB_VERSION="${SMB_VERSION:-3.0}"  # SMB protocol version (2.0, 2.1, 3.0)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if mount point exists and is mounted
check_mount() {
    if ! mountpoint -q "$MOUNT_POINT"; then
        return 1
    fi
    return 0
}

# Function to mount NAS
mount_nas() {
    log_info "Mounting NAS..."

    # Create mount point if it doesn't exist
    if [ ! -d "$MOUNT_POINT" ]; then
        log_info "Creating mount point: $MOUNT_POINT"
        sudo mkdir -p "$MOUNT_POINT"
    fi

    # Mount the NAS share
    sudo mount -t cifs "//$NAS_HOST/$NAS_SHARE" "$MOUNT_POINT" \
        -o username="$NAS_USER",password="$NAS_PASSWORD",vers="$SMB_VERSION",uid=$(id -u),gid=$(id -g)

    if [ $? -eq 0 ]; then
        log_info "NAS mounted successfully at $MOUNT_POINT"
        return 0
    else
        log_error "Failed to mount NAS"
        return 1
    fi
}

# Function to unmount NAS
unmount_nas() {
    if check_mount; then
        log_info "Unmounting NAS..."
        sudo umount "$MOUNT_POINT"
    fi
}

# Function to calculate MD5 hash
calculate_hash() {
    local file="$1"
    if [ ! -f "$file" ]; then
        echo ""
        return 1
    fi
    md5sum "$file" | awk '{print $1}'
}

# Function to find next available backup number
get_next_backup_number() {
    local base_path="$1"
    local dir=$(dirname "$base_path")
    local filename=$(basename "$base_path")
    local name="${filename%.*}"
    local ext="${filename##*.}"

    local counter=1
    while [ -f "${dir}/${name}.${counter}.${ext}" ]; do
        ((counter++))
    done
    echo "$counter"
}

# Main script
main() {
    log_info "Starting NAS video sync..."

    # Check if local file exists
    if [ ! -f "$LOCAL_VIDEO_PATH" ]; then
        log_warn "Local file does not exist: $LOCAL_VIDEO_PATH"
        log_info "Will copy from NAS if available"
    fi

    # Check if NAS is already mounted
    local should_unmount=false
    if ! check_mount; then
        should_unmount=true
        if ! mount_nas; then
            log_error "Cannot proceed without NAS access"
            exit 1
        fi
    else
        log_info "NAS already mounted at $MOUNT_POINT"
    fi

    # Construct full path to NAS file
    local nas_file="$MOUNT_POINT$NAS_VIDEO_PATH"

    # Check if NAS file exists
    if [ ! -f "$nas_file" ]; then
        log_error "NAS file not found: $nas_file"
        if [ "$should_unmount" = true ]; then
            unmount_nas
        fi
        exit 1
    fi

    # Calculate hashes
    log_info "Calculating MD5 hash of NAS file..."
    local nas_hash=$(calculate_hash "$nas_file")

    if [ -f "$LOCAL_VIDEO_PATH" ]; then
        log_info "Calculating MD5 hash of local file..."
        local local_hash=$(calculate_hash "$LOCAL_VIDEO_PATH")

        log_info "NAS hash:   $nas_hash"
        log_info "Local hash: $local_hash"

        # Compare hashes
        if [ "$nas_hash" = "$local_hash" ]; then
            log_info "Hashes match - files are identical. No action needed."
        else
            log_warn "Hashes differ - files are different!"

            # Get next backup number
            local backup_num=$(get_next_backup_number "$LOCAL_VIDEO_PATH")
            local dir=$(dirname "$LOCAL_VIDEO_PATH")
            local filename=$(basename "$LOCAL_VIDEO_PATH")
            local name="${filename%.*}"
            local ext="${filename##*.}"
            local backup_path="${dir}/${name}.${backup_num}.${ext}"

            # Rename local file
            log_info "Renaming local file to: $backup_path"
            mv "$LOCAL_VIDEO_PATH" "$backup_path"

            # Copy new file from NAS
            log_info "Copying new file from NAS..."
            cp "$nas_file" "$LOCAL_VIDEO_PATH"

            log_info "Sync complete! Old file backed up as: $(basename "$backup_path")"
        fi
    else
        # Local file doesn't exist, just copy
        log_info "Local file doesn't exist, copying from NAS..."

        # Create directory if needed
        local dir=$(dirname "$LOCAL_VIDEO_PATH")
        mkdir -p "$dir"

        cp "$nas_file" "$LOCAL_VIDEO_PATH"
        log_info "File copied successfully!"
    fi

    # Unmount if we mounted it
    if [ "$should_unmount" = true ]; then
        unmount_nas
    fi

    log_info "Done!"
}

# Trap to ensure unmount on error
trap 'log_error "Script interrupted"; unmount_nas; exit 1' INT TERM

# Run main function
main

# NAS Video Sync Script

Bash script that synchronizes video files from a NAS to local storage using MD5 hash comparison.

## Features

- Connects to NAS via SMB/CIFS mount
- Compares MD5 hashes to detect file changes
- Automatically backs up old local files with numerical increments
- Only copies when files differ (saves bandwidth and time)
- Automatic mount/unmount handling

## Prerequisites

- `cifs-utils` package installed (for SMB mounting)
- `md5sum` utility (usually pre-installed)
- sudo access (for mounting)

Install on Ubuntu/Debian:
```bash
sudo apt-get install cifs-utils
```

## Setup

1. Copy the example configuration:
```bash
cp sync_nas_video.conf.example sync_nas_video.conf
```

2. Edit `sync_nas_video.conf` with your settings:
```bash
nano sync_nas_video.conf
```

3. Make the script executable:
```bash
chmod +x sync_nas_video.sh
```

## Automatic Execution (Systemd Service)

### Quick Install
Run the sync script automatically every 24 hours:

```bash
chmod +x install-service.sh
./install-service.sh
```

This installs a systemd service and timer that runs the script every 24 hours.

### Service Management

**Check timer status:**
```bash
sudo systemctl status nas-video-sync.timer
```

**View logs:**
```bash
sudo journalctl -u nas-video-sync -f
```

**Run manually now:**
```bash
sudo systemctl start nas-video-sync.service
```

**List all timers:**
```bash
systemctl list-timers
```

**Uninstall service:**
```bash
chmod +x uninstall-service.sh
./uninstall-service.sh
```

### Customizing Schedule

Edit `/etc/systemd/system/nas-video-sync.timer` to change the schedule:

```ini
# Run every 12 hours instead of 24
OnUnitActiveSec=12h

# Or run at 2 AM daily
OnCalendar=*-*-* 02:00:00

# Or run twice daily at 2 AM and 2 PM
OnCalendar=*-*-* 02,14:00:00
```

After editing, reload systemd:
```bash
sudo systemctl daemon-reload
sudo systemctl restart nas-video-sync.timer
```

## Manual Usage

### Option 1: Using configuration file
```bash
source sync_nas_video.conf && ./sync_nas_video.sh
```

### Option 2: Environment variables
```bash
NAS_USER="admin" \
NAS_PASSWORD="password123" \
NAS_HOST="192.168.1.100" \
NAS_SHARE="videos" \
NAS_VIDEO_PATH="/Movies/movie.mp4" \
LOCAL_VIDEO_PATH="/home/user/Videos/movie.mp4" \
./sync_nas_video.sh
```

### Option 3: Edit defaults in script
Modify the configuration section at the top of `sync_nas_video.sh`

## How It Works

1. Mounts the NAS share (or uses existing mount)
2. Calculates MD5 hash of the video file on NAS
3. Calculates MD5 hash of the local video file
4. Compares hashes:
   - **If identical**: Does nothing (files are the same)
   - **If different**:
     - Renames local file to `filename.1.ext` (or `.2`, `.3`, etc.)
     - Copies new file from NAS
5. Unmounts NAS (if script mounted it)

## Example

If you have:
- Local file: `/home/user/video.mp4`
- NAS file changes

The script will:
1. Rename `/home/user/video.mp4` → `/home/user/video.1.mp4`
2. Copy new version from NAS → `/home/user/video.mp4`

Next time it runs with a different file:
1. Rename `/home/user/video.mp4` → `/home/user/video.2.mp4`
2. Copy new version from NAS → `/home/user/video.mp4`

## Security Note

Avoid hardcoding passwords in the script. Consider:
- Using a credentials file with restricted permissions (chmod 600)
- Using environment variables
- Setting up passwordless mount via `/etc/fstab` with credentials file

## Troubleshooting

**Permission denied when mounting:**
- Ensure you have sudo access
- Check NAS credentials are correct

**Mount point busy:**
- Check if NAS is already mounted: `mountpoint /mnt/nas`
- Manually unmount: `sudo umount /mnt/nas`

**Hash calculation slow:**
- MD5 is already optimized for speed
- For very large files, this is normal (video hashing takes time)

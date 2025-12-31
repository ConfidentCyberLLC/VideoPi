# Video Kiosk Service

Systemd service that automatically plays an MP4 video on boot in fullscreen kiosk mode.

## Features

- ✓ Auto-plays video on system boot
- ✓ Fullscreen with no decorations
- ✓ Audio muted (no sound)
- ✓ No title or controls displayed
- ✓ Loops forever
- ✓ Auto-restarts if it crashes
- ✓ Hardware acceleration enabled
- ✓ Optional keyboard control disable

## Use Cases

- Digital signage
- Information displays
- Video loops for events
- Kiosk displays
- Art installations
- Store displays

## Prerequisites

**Required:**
- `mpv` video player
- X11 graphical environment
- Systemd-based Linux distribution

**Install mpv:**
```bash
# Ubuntu/Debian
sudo apt-get install mpv

# Fedora
sudo dnf install mpv

# Arch Linux
sudo pacman -S mpv

# Raspberry Pi OS
sudo apt-get install mpv
```

## Quick Installation

```bash
chmod +x install-video-kiosk.sh
./install-video-kiosk.sh
```

The installer will:
1. Check if mpv is installed
2. Ask for the video file path
3. Configure the service
4. Ask about keyboard controls
5. Enable auto-start on boot
6. Optionally start the video immediately

## Manual Installation

1. Edit `video-kiosk.service` and update:
   - `User=%u` → your username
   - `/path/to/your/video.mp4` → your video path
   - `XAUTHORITY` path if needed

2. Install the service:
```bash
sudo cp video-kiosk.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable video-kiosk.service
sudo systemctl start video-kiosk.service
```

## Service Management

**Start video:**
```bash
sudo systemctl start video-kiosk
```

**Stop video:**
```bash
sudo systemctl stop video-kiosk
```

**Check status:**
```bash
sudo systemctl status video-kiosk
```

**View logs:**
```bash
sudo journalctl -u video-kiosk -f
```

**Disable auto-start:**
```bash
sudo systemctl disable video-kiosk
```

**Re-enable auto-start:**
```bash
sudo systemctl enable video-kiosk
```

## Keyboard Controls

If keyboard controls are NOT disabled during installation:

- `q` - Quit video player
- `f` - Toggle fullscreen
- `Space` - Pause/Resume
- `Left/Right arrows` - Seek backward/forward
- `9/0` - Volume down/up (though audio is muted)

To completely disable keyboard input, the service includes `--no-input-default-bindings`.

## Changing the Video

**Method 1: Edit the service file**
```bash
sudo nano /etc/systemd/system/video-kiosk.service
# Change the video path in ExecStart
sudo systemctl daemon-reload
sudo systemctl restart video-kiosk
```

**Method 2: Reinstall**
```bash
./uninstall-video-kiosk.sh
./install-video-kiosk.sh
```

## Advanced Configuration

### Multiple Videos (Playlist)

To play multiple videos in sequence:

1. Create a playlist file:
```bash
cat > /home/user/playlist.m3u << EOF
/home/user/Videos/video1.mp4
/home/user/Videos/video2.mp4
/home/user/Videos/video3.mp4
EOF
```

2. Edit service to use playlist:
```bash
sudo nano /etc/systemd/system/video-kiosk.service
# Change the last line to:
# --playlist=/home/user/playlist.m3u
```

### Adjust Video Scaling

Edit the service and modify these options:

```ini
# Stretch to fill screen (may distort)
--no-keepaspect

# Keep aspect ratio with black bars
--keepaspect

# Pan and scan (crop to fill)
--video-aspect-override=16:9 --panscan=1.0
```

### Change Display

If you have multiple monitors:

```ini
# Use second display
Environment=DISPLAY=:0.1

# Or specific monitor via mpv
--screen=1
```

### Delay Start

Increase delay if video doesn't start:

```ini
# Wait 10 seconds instead of 5
ExecStartPre=/bin/sleep 10
```

## Troubleshooting

### Video doesn't start on boot

**Check service status:**
```bash
sudo systemctl status video-kiosk
```

**Check logs:**
```bash
sudo journalctl -u video-kiosk -n 50
```

**Common issues:**
- X server not ready: Increase `ExecStartPre` delay
- Wrong DISPLAY: Check with `echo $DISPLAY`
- Wrong XAUTHORITY: Check path exists
- Video file moved: Update service with new path

### Black screen or no video

```bash
# Test mpv manually first
mpv --fs --loop /path/to/video.mp4

# Check if X is accessible
echo $DISPLAY
xhost +local:
```

### Permission denied

```bash
# Check X authority
ls -la ~/.Xauthority
xauth list
```

### Video plays but not fullscreen

- Check monitor resolution
- Try removing `--no-keepaspect-window`
- Add `--geometry=1920x1080` with your resolution

### High CPU usage

- Enable hardware decoding (already included):
  ```
  --hwdec=auto
  ```
- Check supported formats:
  ```bash
  mpv --hwdec=help
  ```

## Raspberry Pi Specific

For Raspberry Pi, you might want to use hardware video decoding:

```ini
# In the service file, add:
--hwdec=rpi
--vo=gpu
```

Or use `omxplayer` instead of `mpv`:
```ini
ExecStart=/usr/bin/omxplayer \
    --loop \
    --no-osd \
    --aspect-mode fill \
    /path/to/video.mp4
```

## Disable Screen Blanking

To prevent screen from turning off:

**Method 1: X11 settings**
```bash
# Add to /etc/X11/xinit/xinitrc or ~/.xinitrc
xset s off
xset -dpms
xset s noblank
```

**Method 2: Systemd service**
Add to the service file before `ExecStart`:
```ini
ExecStartPre=/usr/bin/xset s off
ExecStartPre=/usr/bin/xset -dpms
ExecStartPre=/usr/bin/xset s noblank
```

## Uninstall

```bash
chmod +x uninstall-video-kiosk.sh
./uninstall-video-kiosk.sh
```

## Security Notes

For a public kiosk:
- Disable keyboard controls (use `--no-input-default-bindings`)
- Disable TTY switching: `sudo systemctl mask getty@tty1.service`
- Auto-login to a restricted user account
- Remove/hide window manager panels and menus
- Consider using a minimal window manager like `openbox`

## Performance Tips

- Use H.264 encoded videos (widely hardware accelerated)
- Avoid very high resolution (1080p is usually sufficient)
- Enable hardware decoding (`--hwdec=auto`)
- Use SSD storage for smoother playback
- Close unnecessary background applications

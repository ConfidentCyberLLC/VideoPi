# Alternative Video Players for Kiosk Mode

While the default service uses `mpv`, here are alternatives depending on your needs:

## MPV (Default - Recommended)

**Pros:**
- Lightweight and fast
- Excellent hardware acceleration
- Clean command-line interface
- Low resource usage
- Great format support

**Cons:**
- Minimal GUI (perfect for kiosk, actually)

**Command:**
```bash
mpv --fs --no-audio --loop --no-osc --osd-level=0 video.mp4
```

---

## VLC

**Pros:**
- Very popular, well-supported
- Excellent format compatibility
- Good hardware acceleration

**Cons:**
- Heavier than mpv
- Harder to completely hide controls

**Command:**
```bash
vlc --fullscreen --no-audio --loop --no-video-title-show \
    --no-osd --qt-minimal-view video.mp4
```

**Service file changes:**
```ini
ExecStart=/usr/bin/vlc \
    --fullscreen \
    --no-audio \
    --loop \
    --no-video-title-show \
    --no-osd \
    --qt-minimal-view \
    --no-qt-privacy-ask \
    --no-qt-error-dialogs \
    /path/to/video.mp4
```

---

## OMXPlayer (Raspberry Pi)

**Pros:**
- Optimized for Raspberry Pi
- Very low CPU usage
- Excellent hardware decoding

**Cons:**
- Only works on Raspberry Pi
- Deprecated (but still works)

**Command:**
```bash
omxplayer --loop --no-osd --aspect-mode fill video.mp4
```

**Service file changes:**
```ini
ExecStart=/usr/bin/omxplayer \
    --loop \
    --no-osd \
    --aspect-mode fill \
    --no-keys \
    /path/to/video.mp4
```

---

## FFplay (from FFmpeg)

**Pros:**
- Very lightweight
- No dependencies beyond ffmpeg
- Fast startup

**Cons:**
- Limited control options
- No loop option (need wrapper script)

**Command:**
```bash
ffplay -fs -an -autoexit -loop 0 video.mp4
```

**Service file changes:**
```ini
ExecStart=/usr/bin/ffplay \
    -fs \
    -an \
    -loop 0 \
    -showmode 0 \
    -loglevel quiet \
    /path/to/video.mp4
```

---

## MPlayer

**Pros:**
- Very mature and stable
- Low resource usage
- Good compatibility

**Cons:**
- Less actively maintained
- Older codebase

**Command:**
```bash
mplayer -fs -nosound -loop 0 -nogui -nolirc -really-quiet video.mp4
```

**Service file changes:**
```ini
ExecStart=/usr/bin/mplayer \
    -fs \
    -nosound \
    -loop 0 \
    -nogui \
    -nolirc \
    -really-quiet \
    -zoom \
    /path/to/video.mp4
```

---

## Comparison Table

| Player    | Size    | HW Accel | Pi Support | Ease of Use | Recommended |
|-----------|---------|----------|------------|-------------|-------------|
| mpv       | Small   | ⭐⭐⭐⭐⭐ | ✓          | ⭐⭐⭐⭐⭐    | ✓ Best     |
| VLC       | Large   | ⭐⭐⭐⭐   | ✓          | ⭐⭐⭐⭐      | Good       |
| omxplayer | Tiny    | ⭐⭐⭐⭐⭐ | ✓ Only Pi  | ⭐⭐⭐       | Pi only    |
| ffplay    | Small   | ⭐⭐⭐     | ✓          | ⭐⭐         | Basic use  |
| mplayer   | Small   | ⭐⭐⭐⭐   | ✓          | ⭐⭐⭐       | Legacy     |

---

## How to Switch Players

1. Install the alternative player:
```bash
# VLC
sudo apt-get install vlc

# FFplay (part of ffmpeg)
sudo apt-get install ffmpeg

# MPlayer
sudo apt-get install mplayer

# OMXPlayer (Raspberry Pi)
sudo apt-get install omxplayer
```

2. Edit the service file:
```bash
sudo nano /etc/systemd/system/video-kiosk.service
```

3. Replace the `ExecStart` line with the command for your chosen player

4. Reload and restart:
```bash
sudo systemctl daemon-reload
sudo systemctl restart video-kiosk
```

---

## Recommendation

**For most users:** Use `mpv` (default) - best balance of features, performance, and ease of use

**For Raspberry Pi:** Use `mpv` or `omxplayer` for best hardware acceleration

**For maximum compatibility:** Use `VLC` if you need to play unusual formats

**For minimal system:** Use `ffplay` on very resource-constrained systems

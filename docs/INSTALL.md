# Installation Guide

## Prerequisites

- Raspberry Pi 4 (4GB RAM) with Raspberry Pi OS (Debian Trixie/13) 64-bit
- Pi connected via ethernet (recommended — disable WiFi after setup)
- SSH access to Pi
- In-ceiling speakers with wired runs to central media area
- Fosi Audio ZA3 amplifiers + 48V PSUs (one per zone)
- Sabrent USB audio adapters (one per zone)

---

## Step 1 — Flash Raspberry Pi OS

Use Raspberry Pi Imager on your Mac/PC:

1. Choose **Raspberry Pi OS (Debian Trixie) 64-bit**
2. Click the gear icon and configure:
   - Hostname: `audioplayer`
   - Enable SSH
   - Username: `your-username`
   - WiFi credentials (backup only — use ethernet)
3. Flash to SD card and boot Pi

---

## Step 2 — Initial Setup

SSH into the Pi and update:

```bash
sudo apt update && sudo apt upgrade -y
```

Disable WiFi (optional but recommended for audio stability):

```bash
sudo rfkill block wifi
echo "dtoverlay=disable-wifi" | sudo tee -a /boot/firmware/config.txt
```

---

## Step 3 — Install Software

```bash
sudo apt install -y snapserver snapclient shairport-sync snapweb ffmpeg netcat-traditional
```

Verify versions:
```bash
snapserver --version   # should be 0.31.0
shairport-sync --version  # should show AirPlay2 in feature list
```

---

## Step 4 — Build and Install nqptp

nqptp is required for AirPlay 2 timing:

```bash
sudo apt install -y autoconf automake build-essential
git clone https://github.com/mikebrady/nqptp.git
cd nqptp
autoreconf -fi
./configure --with-systemd-startup
make
sudo make install
sudo systemctl enable nqptp
sudo systemctl start nqptp
cd ..
```

---

## Step 5 — Configure shairport-sync

Edit `/etc/shairport-sync.conf`:

```
general = {
    name = "Kitchen";   // AirPlay device name shown on iPhone
    output_backend = "pipe";
};

pipe = {
    name = "/tmp/shairport-sync-audio";
};
```

Disable standalone service (snapserver manages it):

```bash
sudo systemctl disable shairport-sync
sudo systemctl stop shairport-sync
```

---

## Step 6 — Configure snapserver

Copy the config file:

```bash
sudo cp config/snapserver.conf /etc/snapserver.conf
sudo cp config/snapserver-defaults /etc/default/snapserver
```

Or manually create `/etc/snapserver.conf`:

```ini
[server]
threads = -1

[stream]
source = airplay:///shairport-sync?name=Kitchen&devicename=Kitchen&port=5000
source = airplay:///shairport-sync?name=Dining&devicename=Dining&port=5001
source = tcp://127.0.0.1:4953?name=TTS&mode=server

[http]
enabled = true
port = 1780
doc_root = /usr/share/snapweb/
```

And `/etc/default/snapserver`:

```
SNAPSERVER_OPTS="--config /etc/snapserver.conf"
```

---

## Step 7 — Configure snapclients

### Kitchen (card 3)

Edit `/etc/default/snapclient`:
```
SNAPCLIENT_OPTS="--host localhost --soundcard hw:3,0 --hostID kitchen"
```

### Dining (card 4)

Create `/etc/systemd/system/snapclient-dining.service`:
```ini
[Unit]
Description=Snapcast client - Dining
After=network.target snapserver.service

[Service]
ExecStart=/usr/bin/snapclient --logsink=system --host localhost --soundcard hw:4,0 --hostID dining
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

Enable:
```bash
sudo systemctl daemon-reload
sudo systemctl enable snapclient-dining
```

> **Note:** Card numbers (hw:3,0 and hw:4,0) depend on which USB port each Sabrent adapter is plugged into. Check with `aplay -l` and adjust accordingly.

---

## Step 8 — Set ALSA Volumes

```bash
# Set both cards to 100%
amixer -c 3 sset Speaker 100%
amixer -c 4 sset Speaker 100%
sudo alsactl store
```

---

## Step 9 — Install TTS Announce Script

```bash
sudo cp scripts/tts-announce.sh /usr/local/bin/tts-announce.sh
sudo chmod +x /usr/local/bin/tts-announce.sh
```

---

## Step 10 — Install Snapcast Init Service

This ensures group assignments persist across reboots:

```bash
sudo cp scripts/snapcast-init.sh /usr/local/bin/snapcast-init.sh
sudo chmod +x /usr/local/bin/snapcast-init.sh
```

> **Edit the group IDs in snapcast-init.sh** — see Step 12 for how to find them.

```bash
sudo cp systemd/snapcast-init.service /etc/systemd/system/snapcast-init.service
sudo systemctl enable snapcast-init
```

---

## Step 11 — Start Everything

```bash
sudo systemctl start snapserver
sudo systemctl start snapclient
sudo systemctl start snapclient-dining
sudo systemctl start nqptp
```

Check status:
```bash
sudo systemctl status snapserver
```

You should see shairport-sync instances launched as child processes.

Open Snapweb at `http://audioplayer.local:1780` to verify streams and clients.

---

## Step 12 — Find and Set Group IDs

After starting, discover group IDs:

```bash
curl http://localhost:1780/jsonrpc \
  -d '{"id":1,"jsonrpc":"2.0","method":"Server.GetStatus"}' \
  | python3 -m json.tool | grep -E '"id":|"stream_id"'
```

**Verify which group ID corresponds to which physical room using the mute test:**

```bash
# Mute a group — listen to which room goes silent
curl http://localhost:1780/jsonrpc \
  -d '{"id":1,"jsonrpc":"2.0","method":"Group.SetMute","params":{"id":"GROUP_ID_HERE","mute":true}}'

# Unmute
curl http://localhost:1780/jsonrpc \
  -d '{"id":1,"jsonrpc":"2.0","method":"Group.SetMute","params":{"id":"GROUP_ID_HERE","mute":false}}'
```

Update `snapcast-init.sh` with the verified group IDs.

---

## Step 13 — Test AirPlay

On your iPhone:
1. Play any music
2. Tap the AirPlay icon
3. Select **"Kitchen"** or **"Dining"**
4. Audio should come through the ceiling speakers within 2-3 seconds

---

## Step 14 — Home Assistant Setup

See [ha-config/README.md](ha-config/README.md) for HA integration.

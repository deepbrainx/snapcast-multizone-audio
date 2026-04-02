# Home Assistant Integration

## Prerequisites

- Snapcast integration installed (built-in, search in Integrations)
- snapcast-ha-player installed via HACS (for TTS playback)
- Chime TTS installed via HACS (for TTS generation)
- Piper TTS add-on installed and running
- SSH key set up between HA and Pi (see below)

---

## Step 1 — Add Snapcast Integration

1. Settings → Devices & Services → Add Integration
2. Search **Snapcast**
3. Host: `YOUR_PI_IP`
4. Port: `1705`

This gives you volume control and mute for each zone.

---

## Step 2 — Set Up SSH Key

In the HA terminal (SSH & Terminal add-on):

```bash
ssh-keygen -t ed25519 -f /config/id_rsa -N ""
cat /config/id_rsa.pub
```

Copy the public key. On the Pi:

```bash
mkdir -p ~/.ssh
echo "PASTE_PUBLIC_KEY_HERE" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

Test from HA terminal:

```bash
ssh -i /config/id_rsa -o StrictHostKeyChecking=no USERNAME@PI_IP echo "connected"
```

---

## Step 3 — Add configuration.yaml entries

Add to `configuration.yaml` (replace `YOUR_PI_IP`, `YOUR_USERNAME`, and group IDs):

```yaml
media_player:
  - platform: snapcast_player
    host: YOUR_PI_IP
    start_delay: 1s

shell_command:
  tts_announce: "ssh -i /config/id_rsa -o StrictHostKeyChecking=no YOUR_USERNAME@YOUR_PI_IP '/usr/local/bin/tts-announce.sh {{ url }}'"
  tts_switch_kitchen: "curl http://YOUR_PI_IP:1780/jsonrpc -d '{\"id\":1,\"jsonrpc\":\"2.0\",\"method\":\"Group.SetStream\",\"params\":{\"id\":\"KITCHEN_GROUP_ID\",\"stream_id\":\"TTS\"}}'"
  tts_restore_kitchen: "curl http://YOUR_PI_IP:1780/jsonrpc -d '{\"id\":1,\"jsonrpc\":\"2.0\",\"method\":\"Group.SetStream\",\"params\":{\"id\":\"KITCHEN_GROUP_ID\",\"stream_id\":\"Kitchen\"}}'"
  tts_switch_dining: "curl http://YOUR_PI_IP:1780/jsonrpc -d '{\"id\":1,\"jsonrpc\":\"2.0\",\"method\":\"Group.SetStream\",\"params\":{\"id\":\"DINING_GROUP_ID\",\"stream_id\":\"TTS\"}}'"
  tts_restore_dining: "curl http://YOUR_PI_IP:1780/jsonrpc -d '{\"id\":1,\"jsonrpc\":\"2.0\",\"method\":\"Group.SetStream\",\"params\":{\"id\":\"DINING_GROUP_ID\",\"stream_id\":\"Dining\"}}'"
```

Restart HA after saving.

---

## Step 4 — Hourly Time Announcement Automation

See `automations/hourly-announcement.yaml` for the complete automation.

Import it via Settings → Automations → Import, or copy/paste the YAML.

---

## Finding Group IDs

SSH to Pi and run:

```bash
curl http://localhost:1780/jsonrpc \
  -d '{"id":1,"jsonrpc":"2.0","method":"Server.GetStatus"}' \
  | python3 -m json.tool | grep -E '"id":|"stream_id"'
```

**Always verify group IDs using the mute test** — the physical room a group controls may not match its logical label:

```bash
# Mute a group
curl http://localhost:1780/jsonrpc \
  -d '{"id":1,"jsonrpc":"2.0","method":"Group.SetMute","params":{"id":"GROUP_ID","mute":true}}'

# Unmute
curl http://localhost:1780/jsonrpc \
  -d '{"id":1,"jsonrpc":"2.0","method":"Group.SetMute","params":{"id":"GROUP_ID","mute":false}}'
```

Whichever room goes silent when muted is that group ID.

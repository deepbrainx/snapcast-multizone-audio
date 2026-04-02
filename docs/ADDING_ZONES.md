# Adding More Zones

Each additional zone requires a new USB audio adapter, amplifier, and a few config changes.

## Hardware

1. Purchase another Sabrent AU-MMSA USB audio adapter
2. Purchase another Fosi Audio ZA3 + 48V 5A PSU
3. Connect speaker wires to ZA3 terminals
4. Connect Sabrent → 3.5mm to RCA → ZA3 RCA input

## Step 1 — Find New Card Number

Plug in the new Sabrent USB adapter and check the card number:

```bash
aplay -l
```

Note the card number for the new device (e.g., card 5).

## Step 2 — Set ALSA Volume

```bash
amixer -c 5 sset Speaker 100%
sudo alsactl store
```

## Step 3 — Add AirPlay Source to snapserver

Edit `/etc/snapserver.conf` and add a new source line:

```ini
source = airplay:///shairport-sync?name=LivingRoom&devicename=LivingRoom&port=5002
```

Increment the port number for each new zone (5000, 5001, 5002...).

## Step 4 — Create New snapclient Service

Create `/etc/systemd/system/snapclient-livingroom.service`:

```ini
[Unit]
Description=Snapcast client - Living Room
After=network.target snapserver.service

[Service]
ExecStart=/usr/bin/snapclient --logsink=system --host localhost --soundcard hw:5,0 --hostID livingroom
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable snapclient-livingroom
sudo systemctl start snapclient-livingroom
```

## Step 5 — Restart snapserver

```bash
sudo systemctl restart snapserver
```

The new "LivingRoom" AirPlay device should appear on your iPhone.

## Step 6 — Find New Group ID

```bash
curl http://localhost:1780/jsonrpc \
  -d '{"id":1,"jsonrpc":"2.0","method":"Server.GetStatus"}' \
  | python3 -m json.tool | grep -E '"id":|"stream_id"'
```

Verify the correct group ID using the mute test (see INSTALL.md Step 12).

## Step 7 — Update snapcast-init.sh

Add the new group assignment to `/usr/local/bin/snapcast-init.sh`:

```bash
curl http://localhost:1780/jsonrpc \
  -d '{"id":1,"jsonrpc":"2.0","method":"Group.SetStream","params":{"id":"NEW_GROUP_ID","stream_id":"LivingRoom"}}'
```

## Step 8 — Add HA Shell Commands

In `configuration.yaml`, add to `shell_command:`:

```yaml
  tts_switch_livingroom: "curl http://SNAPCAST_HOST:1780/jsonrpc -d '{\"id\":1,\"jsonrpc\":\"2.0\",\"method\":\"Group.SetStream\",\"params\":{\"id\":\"NEW_GROUP_ID\",\"stream_id\":\"TTS\"}}'"
  tts_restore_livingroom: "curl http://SNAPCAST_HOST:1780/jsonrpc -d '{\"id\":1,\"jsonrpc\":\"2.0\",\"method\":\"Group.SetStream\",\"params\":{\"id\":\"NEW_GROUP_ID\",\"stream_id\":\"LivingRoom\"}}'"
```

Restart HA and add the new zone to your TTS automation.

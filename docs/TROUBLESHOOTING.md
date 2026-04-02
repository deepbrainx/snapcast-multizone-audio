# Troubleshooting

## AirPlay Device Not Appearing on iPhone

1. Confirm snapserver is running: `sudo systemctl status snapserver`
2. Confirm shairport-sync is running as child process: `ps aux | grep shairport`
3. Confirm nqptp is running: `sudo systemctl status nqptp`
4. Check Avahi (mDNS) is working: `sudo systemctl status avahi-daemon`
5. Ensure Pi and iPhone are on the same network/VLAN
6. If using VLANs, enable mDNS reflection in your router/switch

## No Audio Through Speakers

1. Check ALSA volume: `amixer -c X scontents` — ensure Speaker is at 100%
2. Check physical connections:
   - 3.5mm plug in **green** jack on Sabrent (not pink)
   - RCA cables fully seated in ZA3 inputs
   - ZA3 input selector set to RCA
   - ZA3 volume knob turned up
   - Speaker wire terminals making good contact
3. Test hardware directly: `speaker-test -c 2 -t wav -D hw:X,0`
4. Check snapclient is running: `sudo systemctl status snapclient`

## Audio Sounds Like Static/Noise

Possible causes:
- Loose RCA connection — reseat all cables
- USB noise from Pi — try a different USB port
- Sample rate mismatch — check `cat /proc/asound/cardX/stream0`

## Snapcast Group Assignments Reset After Reboot

Verify snapcast-init service is running:

```bash
sudo systemctl status snapcast-init
journalctl -u snapcast-init
```

If groups are wrong after boot, the group IDs in `snapcast-init.sh` may be incorrect. Re-verify with the mute test:

```bash
curl http://localhost:1780/jsonrpc \
  -d '{"id":1,"jsonrpc":"2.0","method":"Group.SetMute","params":{"id":"GROUP_ID","mute":true}}'
```

AirPlay and listen — whichever room goes silent is that group ID.

## Wrong Room Playing

The physical mapping of group IDs to rooms can be counterintuitive. The group ID is determined by which Sabrent is on which USB port, not by the hostID name. Always verify with the mute test after any hardware changes.

## Version Mismatch Between snapserver and snapclient

Both must be the same version. Check:

```bash
snapserver --version
snapclient --version
```

If mismatched, install from the same Debian repository:

```bash
sudo apt install -y snapserver snapclient
```

## TTS Not Playing

1. Verify SSH key works from HA to Pi:
   ```bash
   ssh -i /config/id_rsa -o StrictHostKeyChecking=no USERNAME@PI_IP echo "connected"
   ```
2. Test tts-announce.sh directly on Pi:
   ```bash
   /usr/local/bin/tts-announce.sh "https://your-ha-url/local/chime_tts/test.mp3"
   ```
3. Check if nc is already running and blocking: `sudo pkill nc`
4. Verify group is assigned to TTS stream in Snapweb before playing

## Snapserver Crashes on Start (SIGABRT)

Usually caused by missing or corrupt state directory:

```bash
sudo mkdir -p /var/lib/snapserver
sudo chown _snapserver:_snapserver /var/lib/snapserver
sudo systemctl restart snapserver
```

## "No chunks available" in snapclient logs

Usually a timing/clock sync issue or version mismatch. Check:

```bash
timedatectl status  # ensure NTP is active
```

If `diff to server` in logs is very large (>1000ms), clocks are out of sync. On Pi:

```bash
sudo timedatectl set-ntp true
```

## Checking Logs

```bash
# Snapserver
sudo journalctl -u snapserver -f

# Snapclient (kitchen)
sudo journalctl -u snapclient -f

# Snapclient (dining)
sudo journalctl -u snapclient-dining -f

# nqptp
sudo journalctl -u nqptp -f

# Snapcast init
sudo journalctl -u snapcast-init
```

# Snapcast Multi-Zone Ceiling Speaker Audio System

A self-hosted, whole-home multi-zone audio system using a Raspberry Pi 4, Snapcast, shairport-sync, and Fosi Audio ZA3 amplifiers. Supports AirPlay 2, Spotify Connect, and Home Assistant TTS announcements through in-ceiling speakers.

## Features

- **AirPlay 2** — Stream from iPhone/iPad/Mac to individual rooms
- **Spotify Connect** — Each zone appears as a Spotify device
- **Multi-zone** — Kitchen, dining room, and more zones easily added
- **Home Assistant integration** — Volume control, TTS announcements, automations
- **Hourly time announcements** — Piper TTS via Chime TTS piped to ceiling speakers
- **Snapweb UI** — Browser-based zone management at `http://audioplayer.local:1780`

## Hardware Shopping List

| Item | Notes |
|---|---|
| [Fosi Audio ZA3 Amplifier](https://www.amazon.com/s?k=fosi+audio+za3) | TPA3255, 180W stereo, XLR/RCA inputs |
| [48V 5A DC Power Supply](https://www.amazon.com/s?k=48v+5a+power+supply+center+positive) | One per ZA3, center positive barrel connector |
| [Sabrent USB Audio Adapter](https://www.amazon.com/s?k=sabrent+au-mmsa) | USB DAC, one per zone |
| [3.5mm to Dual RCA Cable](https://www.amazon.com/s?k=3.5mm+to+rca+cable) | Connects Sabrent to ZA3 |
| [Raspberry Pi 4 (4GB)](https://www.amazon.com/s?k=raspberry+pi+4+4gb) | Central hub running all software |
| [USB-A Extension Cables](https://www.amazon.com/s?k=usb+a+male+to+female+extension+6+inch) | For spacing multiple Sabrents on Pi USB ports |

**Cost per zone (approximate):** ~$170 (ZA3 + PSU + Sabrent + cables)  
**Central hub:** ~$55 (Pi 4 4GB)

## Hardware

### Per Zone
- [Fosi Audio ZA3](https://www.fosiaud.com/) Balanced Stereo Amplifier (TPA3255, 180W stereo)
- 48V 5A DC power supply (center positive barrel connector)
- [Sabrent AU-MMSA](https://www.sabrent.com/) USB audio adapter (or similar C-Media USB DAC)
- 3.5mm stereo to dual RCA cable
- Existing in-ceiling speakers with wired runs to central media area

### Central Hub
- Raspberry Pi 4 (4GB RAM recommended)
- USB extension cables or powered 5V USB hub for multiple Sabrent adapters
- MicroSD card (32GB+)

## Software Stack

| Component | Version | Purpose |
|---|---|---|
| Raspberry Pi OS | Debian Trixie (13) 64-bit | Base OS |
| snapserver | 0.31.0 | Audio routing server |
| snapclient | 0.31.0 | Audio output client (one per zone) |
| shairport-sync | 4.3.7 | AirPlay 2 receiver |
| nqptp | latest | AirPlay 2 timing daemon |
| snapweb | 0.9.3 | Web UI |

## Architecture

```
iPhone/Spotify
      │ WiFi/AirPlay 2 / Spotify Connect
      ▼
Raspberry Pi 4 (audioplayer)
├── snapserver
│   ├── shairport-sync (Kitchen AirPlay stream, port 5000)
│   ├── shairport-sync (Dining AirPlay stream, port 5001)
│   └── TCP source (TTS stream, port 4953)
├── snapclient (kitchen) → hw:3,0 → Sabrent → ZA3 → ceiling speakers
└── snapclient (dining)  → hw:4,0 → Sabrent → ZA3 → ceiling speakers
```

## Quick Start

See [docs/INSTALL.md](docs/INSTALL.md) for full installation instructions.

```bash
# 1. Flash Raspberry Pi OS (Trixie 64-bit) to SD card
# 2. SSH into Pi and run setup
git clone https://github.com/YOUR_USERNAME/snapcast-multizone-audio.git
cd snapcast-multizone-audio
./scripts/setup.sh
```

## Home Assistant

See [ha-config/README.md](ha-config/README.md) for HA integration details including:
- Snapcast integration setup
- SSH key configuration for TTS
- Shell commands for stream switching
- Hourly announcement automation

## Adding More Zones

Each additional zone requires:
1. Another Sabrent USB adapter (check new card number with `aplay -l`)
2. Another Fosi ZA3 + 48V PSU
3. Add source line to `/etc/snapserver.conf`
4. Create new `snapclient-ROOM.service`
5. Set ALSA volume: `amixer -c X sset Speaker 100% && sudo alsactl store`
6. Update `snapcast-init.sh` with new group assignment
7. Add HA shell commands for TTS switching

See [docs/ADDING_ZONES.md](docs/ADDING_ZONES.md) for detailed instructions.

## Known Limitations

- Snapcast group assignments reset on snapserver restart — handled by `snapcast-init.service`
- TTS announcements play sequentially per zone (not simultaneous) due to single TCP stream
- Snapcast group IDs for physical rooms may not match logical labels — verify with mute test after any hardware changes

## License

MIT

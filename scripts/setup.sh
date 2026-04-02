#!/bin/bash
# setup.sh
# Automated setup script for snapcast-multizone-audio
# Run on Raspberry Pi 4 after flashing Raspberry Pi OS (Trixie/Debian 13)

set -e

echo "=== Snapcast Multi-Zone Audio Setup ==="
echo ""

# Update system
echo "--- Updating system packages ---"
sudo apt update && sudo apt upgrade -y

# Install required packages
echo "--- Installing packages ---"
sudo apt install -y \
  snapserver \
  snapclient \
  shairport-sync \
  snapweb \
  ffmpeg \
  netcat-traditional \
  autoconf \
  automake \
  build-essential \
  git \
  curl

# Build and install nqptp (required for AirPlay 2)
echo "--- Building nqptp ---"
if [ ! -f /usr/local/bin/nqptp ]; then
  git clone https://github.com/mikebrady/nqptp.git /tmp/nqptp
  cd /tmp/nqptp
  autoreconf -fi
  ./configure --with-systemd-startup
  make
  sudo make install
  cd -
else
  echo "nqptp already installed, skipping."
fi

# Enable and start nqptp
sudo systemctl enable nqptp
sudo systemctl start nqptp

# Disable standalone shairport-sync (snapserver manages it)
sudo systemctl disable shairport-sync 2>/dev/null || true
sudo systemctl stop shairport-sync 2>/dev/null || true

# Install config files
echo "--- Installing config files ---"
sudo cp config/snapserver.conf /etc/snapserver.conf
sudo cp config/snapserver-defaults /etc/default/snapserver
sudo cp config/snapclient-defaults /etc/default/snapclient

# Install systemd services
echo "--- Installing systemd services ---"
sudo cp systemd/snapclient-dining.service /etc/systemd/system/snapclient-dining.service
sudo cp systemd/snapcast-init.service /etc/systemd/system/snapcast-init.service

# Install scripts
echo "--- Installing scripts ---"
sudo cp scripts/snapcast-init.sh /usr/local/bin/snapcast-init.sh
sudo cp scripts/tts-announce.sh /usr/local/bin/tts-announce.sh
sudo chmod +x /usr/local/bin/snapcast-init.sh
sudo chmod +x /usr/local/bin/tts-announce.sh

# Reload systemd
sudo systemctl daemon-reload

# Enable services
echo "--- Enabling services ---"
sudo systemctl enable snapserver
sudo systemctl enable snapclient
sudo systemctl enable snapclient-dining
sudo systemctl enable snapcast-init

# Start services
echo "--- Starting services ---"
sudo systemctl start snapserver
sleep 3
sudo systemctl start snapclient
sudo systemctl start snapclient-dining

echo ""
echo "=== Setup complete! ==="
echo ""
echo "Next steps:"
echo "1. Check card numbers with: aplay -l"
echo "2. Update /etc/default/snapclient if card numbers differ from hw:3,0"
echo "3. Update /etc/systemd/system/snapclient-dining.service if card 4 differs"
echo "4. Set ALSA volumes: amixer -c 3 sset Speaker 100% && amixer -c 4 sset Speaker 100%"
echo "5. Open Snapweb: http://$(hostname).local:1780"
echo "6. Find group IDs and update /usr/local/bin/snapcast-init.sh"
echo "7. See docs/INSTALL.md for Home Assistant setup"

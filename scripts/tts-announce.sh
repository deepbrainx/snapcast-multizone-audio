#!/bin/bash
# tts-announce.sh
# Downloads a TTS audio URL and pipes it into the Snapcast TTS stream via TCP.
# Called from Home Assistant via SSH shell command.
#
# Usage: tts-announce.sh <audio_url>
#
# Prerequisites:
#   - ffmpeg installed on Pi
#   - netcat-traditional installed (provides nc with -q flag)
#   - Snapserver running with TCP source on port 4953
#   - Snapcast group assigned to TTS stream before calling

URL="$1"

if [ -z "$URL" ]; then
  echo "Usage: tts-announce.sh <audio_url>"
  exit 1
fi

# Download and convert audio to raw PCM, pipe to Snapcast TCP source
# -q 1 tells nc to quit 1 second after EOF (closes connection cleanly)
ffmpeg -i "$URL" -f s16le -ar 44100 -ac 2 - 2>/dev/null | nc -q 1 127.0.0.1 4953

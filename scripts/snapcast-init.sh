#!/bin/bash
# snapcast-init.sh
# Assigns Snapcast groups to their correct streams on startup.
# Run after snapserver starts to ensure persistent zone assignments.
#
# IMPORTANT: Group IDs are unique to your installation and depend on
# which Snapcast client connected first and in what order.
# Find your group IDs with:
#   curl http://localhost:1780/jsonrpc \
#     -d '{"id":1,"jsonrpc":"2.0","method":"Server.GetStatus"}' \
#     | python3 -m json.tool | grep -E '"id":|"stream_id"'
#
# Verify which group ID corresponds to which physical room using the mute test:
#   curl http://localhost:1780/jsonrpc \
#     -d '{"id":1,"jsonrpc":"2.0","method":"Group.SetMute","params":{"id":"GROUP_ID","mute":true}}'
# Then AirPlay and listen — whichever room goes silent is that group ID.

# Wait for snapserver to fully initialize
sleep 5

# Replace GROUP_ID_KITCHEN and GROUP_ID_DINING with your actual group IDs
KITCHEN_GROUP="GROUP_ID_KITCHEN"
DINING_GROUP="GROUP_ID_DINING"

echo "Setting Kitchen group ($KITCHEN_GROUP) to Kitchen stream..."
curl -s http://localhost:1780/jsonrpc \
  -d "{\"id\":1,\"jsonrpc\":\"2.0\",\"method\":\"Group.SetStream\",\"params\":{\"id\":\"$KITCHEN_GROUP\",\"stream_id\":\"Kitchen\"}}"

echo ""
echo "Setting Dining group ($DINING_GROUP) to Dining stream..."
curl -s http://localhost:1780/jsonrpc \
  -d "{\"id\":1,\"jsonrpc\":\"2.0\",\"method\":\"Group.SetStream\",\"params\":{\"id\":\"$DINING_GROUP\",\"stream_id\":\"Dining\"}}"

echo ""
echo "Snapcast group assignments complete."

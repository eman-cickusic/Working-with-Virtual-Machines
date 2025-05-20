#!/bin/bash
# Minecraft Server Shutdown Script
# This script gracefully stops the Minecraft server before VM shutdown

# Save the world and stop the server
screen -r mcs -X stuff '/save-all\n/stop\n'

# Wait for the server to stop completely (30 seconds should be enough)
sleep 30

echo "Minecraft server stopped at $(date)"

#!/bin/bash
# Minecraft Server Startup Script
# This script automatically prepares and starts the Minecraft server on VM startup

# Create a mount directory
mkdir -p /home/minecraft

# Mount the data disk (if not already mounted)
if ! grep -q "/home/minecraft" /etc/mtab; then
  mount -o discard,defaults /dev/disk/by-id/google-minecraft-disk /home/minecraft
fi

# Change to minecraft directory
cd /home/minecraft

# Check if server.jar exists
if [ ! -f server.jar ]; then
  # Download the server if it doesn't exist
  wget -O server.jar https://launcher.mojang.com/v1/objects/d0d0fe2b1dc6ab4c65554cb734270872b72dadd6/server.jar
fi

# Check if EULA has been accepted
if [ ! -f eula.txt ] || ! grep -q "eula=true" eula.txt; then
  # Initialize the server to create eula.txt if it doesn't exist
  java -Xmx1024M -Xms1024M -jar server.jar nogui
  # Accept the EULA
  sed -i 's/eula=false/eula=true/g' eula.txt
fi

# Make sure screen is installed
apt-get update
apt-get install -y screen

# Start the server in a screen session
screen -dmS mcs java -Xmx1024M -Xms1024M -jar server.jar nogui

echo "Minecraft server started at $(date)"

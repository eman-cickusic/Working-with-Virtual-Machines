#!/bin/bash
# Minecraft Server Setup Script
# This script automates the entire setup process for a Minecraft server on Google Cloud

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit 1
fi

echo "===== Minecraft Server Setup Script ====="
echo "This script will set up a complete Minecraft server environment"

# Prepare the disk
echo "===== Step 1: Preparing the data disk ====="
mkdir -p /home/minecraft

# Check if the minecraft-disk exists
if [ -e /dev/disk/by-id/google-minecraft-disk ]; then
  echo "Formatting the disk..."
  mkfs.ext4 -F -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/disk/by-id/google-minecraft-disk
  
  echo "Mounting the disk..."
  mount -o discard,defaults /dev/disk/by-id/google-minecraft-disk /home/minecraft
else
  echo "Error: minecraft-disk not found. Please create the disk first."
  exit 1
fi

# Install required packages
echo "===== Step 2: Installing required packages ====="
apt-get update
apt-get install -y default-jre-headless wget screen

# Download and set up Minecraft server
echo "===== Step 3: Setting up Minecraft server ====="
cd /home/minecraft

echo "Downloading Minecraft server..."
wget -O server.jar https://launcher.mojang.com/v1/objects/d0d0fe2b1dc6ab4c65554cb734270872b72dadd6/server.jar

echo "Initializing server..."
java -Xmx1024M -Xms1024M -jar server.jar nogui

# Accept EULA
echo "Accepting EULA..."
sed -i 's/eula=false/eula=true/g' eula.txt

# Create backup script
echo "===== Step 4: Setting up backup system ====="
echo "Please enter a unique name for your backup bucket:"
read BUCKET_NAME

# Creating backup bucket
echo "Creating Cloud Storage bucket..."
gcloud storage buckets create gs://$BUCKET_NAME-minecraft-backup

# Creating backup script
echo "Creating backup script..."
cat > /home/minecraft/backup.sh << EOL
#!/bin/bash
screen -r mcs -X stuff '/save-all\n/save-off\n'
/usr/bin/gcloud storage cp -R \${BASH_SOURCE%/*}/world gs://$BUCKET_NAME-minecraft-backup/\$(date "+%Y%m%d-%H%M%S")-world
screen -r mcs -X stuff '/save-on\n'
EOL

# Make backup script executable
chmod 755 /home/minecraft/backup.sh

# Setting up cron job for backups
echo "Setting up scheduled backups (every 4 hours)..."
(crontab -l 2>/dev/null; echo "0 */4 * * * /home/minecraft/backup.sh") | crontab -

# Create admin script
echo "===== Step 5: Creating administration script ====="
cat > /home/minecraft/mc-admin.sh << EOL
#!/bin/bash
# Minecraft Server Administration Script
# Usage: ./mc-admin.sh [start|stop|backup|status|restart|console]

# Configuration
MINECRAFT_DIR="/home/minecraft"
SCREEN_NAME="mcs"
JAVA_ARGS="-Xmx1024M -Xms1024M"
JAR_FILE="server.jar"

# Check if running as root
if [ "\$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit 1
fi

# Function to check if server is running
is_server_running() {
  if screen -list | grep -q "\$SCREEN_NAME"; then
    return 0
  else
    return 1
  fi
}

# Function to start the server
start_server() {
  if is_server_running; then
    echo "Server is already running"
  else
    echo "Starting Minecraft server..."
    cd \$MINECRAFT_DIR
    screen -dmS \$SCREEN_NAME java \$JAVA_ARGS -jar \$JAR_FILE nogui
    echo "Server started"
  fi
}

# Function to stop the server
stop_server() {
  if is_server_running; then
    echo "Stopping Minecraft server..."
    screen -r \$SCREEN_NAME -X stuff '/save-all\n/stop\n'
    # Wait for the server to stop
    sleep 10
    echo "Server stopped"
  else
    echo "Server is not running"
  fi
}

# Function to create a backup
backup_server() {
  echo "Creating backup..."
  if [ -f "\$MINECRAFT_DIR/backup.sh" ]; then
    cd \$MINECRAFT_DIR
    ./backup.sh
  else
    echo "Backup script not found"
  fi
}

# Function to show server status
server_status() {
  if is_server_running; then
    echo "Server is running"
    echo "To connect to the console, use: sudo screen -r \$SCREEN_NAME"
  else
    echo "Server is not running"
  fi
}

# Function to restart the server
restart_server() {
  echo "Restarting server..."
  stop_server
  sleep 2
  start_server
}

# Function to attach to the console
console() {
  if is_server_running; then
    echo "Connecting to server console..."
    echo "Use Ctrl+A, Ctrl+D to detach from console"
    screen -r \$SCREEN_NAME
  else
    echo "Server is not running"
  fi
}

# Main script logic
case "\$1" in
  start)
    start_server
    ;;
  stop)
    stop_server
    
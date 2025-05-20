#!/bin/bash
# Minecraft Server Administration Script
# Usage: ./mc-admin.sh [start|stop|backup|status|restart|console]

# Configuration
MINECRAFT_DIR="/home/minecraft"
SCREEN_NAME="mcs"
JAVA_ARGS="-Xmx1024M -Xms1024M"
JAR_FILE="server.jar"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit 1
fi

# Function to check if server is running
is_server_running() {
  if screen -list | grep -q "$SCREEN_NAME"; then
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
    cd $MINECRAFT_DIR
    screen -dmS $SCREEN_NAME java $JAVA_ARGS -jar $JAR_FILE nogui
    echo "Server started"
  fi
}

# Function to stop the server
stop_server() {
  if is_server_running; then
    echo "Stopping Minecraft server..."
    screen -r $SCREEN_NAME -X stuff '/save-all\n/stop\n'
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
  if [ -f "$MINECRAFT_DIR/backup.sh" ]; then
    cd $MINECRAFT_DIR
    ./backup.sh
  else
    echo "Backup script not found"
  fi
}

# Function to show server status
server_status() {
  if is_server_running; then
    echo "Server is running"
    echo "To connect to the console, use: sudo screen -r $SCREEN_NAME"
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
    screen -r $SCREEN_NAME
  else
    echo "Server is not running"
  fi
}

# Main script logic
case "$1" in
  start)
    start_server
    ;;
  stop)
    stop_server
    ;;
  backup)
    backup_server
    ;;
  status)
    server_status
    ;;
  restart)
    restart_server
    ;;
  console)
    console
    ;;
  *)
    echo "Usage: $0 {start|stop|backup|status|restart|console}"
    exit 1
    ;;
esac

exit 0

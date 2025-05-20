#!/bin/bash
# Minecraft Server Backup Script
# This script creates a backup of the Minecraft world data and uploads it to Google Cloud Storage

# Save the world data and disable auto-save
screen -r mcs -X stuff '/save-all\n/save-off\n'

# Copy the world data to Google Cloud Storage with timestamp
/usr/bin/gcloud storage cp -R ${BASH_SOURCE%/*}/world gs://${YOUR_BUCKET_NAME}-minecraft-backup/$(date "+%Y%m%d-%H%M%S")-world

# Re-enable auto-save
screen -r mcs -X stuff '/save-on\n'

echo "Backup completed at $(date)"

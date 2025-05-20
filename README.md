# Working with Virtual Machines

This repository contains instructions and scripts for setting up a Minecraft server on Google Cloud Platform. The server runs on a Compute Engine instance with a dedicated persistent disk for world data and includes automated backup functionality.

## Overview

The setup includes:
- A Compute Engine VM instance (e2-medium with 2 vCPU, 4GB RAM)
- A 10-GB boot disk running Debian Linux
- A 50-GB SSD persistent disk for Minecraft world data
- Java Runtime Environment (headless version)
- Minecraft server software
- Firewall configuration for client access
- Automated backup to Cloud Storage

## Prerequisites

- Google Cloud Platform account
- Basic knowledge of Google Cloud Console
- Basic Linux command-line skills

## Setup Instructions

Follow these steps to create your Minecraft server:

### 1. Create the VM Instance

1. Navigate to Compute Engine > VM instances in Google Cloud Console
2. Click "Create instance"
3. Configure the VM with the following specifications:
   - Name: `mc-server`
   - Machine type: e2-medium (2 vCPU, 4 GB RAM)
   - Boot disk: Debian GNU/Linux 12 (bookworm)
   - Add a new disk:
     - Name: `minecraft-disk`
     - Type: SSD Persistent Disk
     - Size: 50 GB
   - Network tag: `minecraft-server`
   - Reserve a static external IP named `mc-server-ip`
   - Under Security > Identity and API access > Access Scopes:
     - Set access for each API
     - Storage: Read Write

### 2. Prepare the Data Disk

Once the VM is created, SSH into it and run the following commands:

```bash
# Create a mount directory
sudo mkdir -p /home/minecraft

# Format the disk
sudo mkfs.ext4 -F -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/disk/by-id/google-minecraft-disk

# Mount the disk
sudo mount -o discard,defaults /dev/disk/by-id/google-minecraft-disk /home/minecraft
```

### 3. Install and Configure the Minecraft Server

```bash
# Update repositories
sudo apt-get update

# Install Java Runtime Environment (headless)
sudo apt-get install -y default-jre-headless

# Navigate to the Minecraft directory
cd /home/minecraft

# Install wget
sudo apt-get install wget

# Download the Minecraft server JAR file
sudo wget https://launcher.mojang.com/v1/objects/d0d0fe2b1dc6ab4c65554cb734270872b72dadd6/server.jar

# Initialize the server (this will create the necessary files)
sudo java -Xmx1024M -Xms1024M -jar server.jar nogui

# Accept the EULA
sudo nano eula.txt
# Change eula=false to eula=true

# Install screen to run the server in the background
sudo apt-get install -y screen

# Start the Minecraft server in a screen session
sudo screen -S mcs java -Xmx1024M -Xms1024M -jar server.jar nogui
```

To detach from the screen session (keep the server running in the background): Press `Ctrl+A, Ctrl+D`
To reattach to the screen: `sudo screen -r mcs`

### 4. Configure Firewall for Client Access

1. In Google Cloud Console, navigate to VPC network > Firewall
2. Click "Create firewall rule"
3. Configure as follows:
   - Name: `minecraft-rule`
   - Target: Specified target tags
   - Target tags: `minecraft-server`
   - Source filter: IPv4 ranges
   - Source IPv4 ranges: `0.0.0.0/0`
   - Protocols and ports: Specified protocols and ports
   - For TCP, specify port `25565`

### 5. Set Up Automatic Backups

1. Create a Cloud Storage bucket:
   ```bash
   export YOUR_BUCKET_NAME=your-unique-bucket-name
   gcloud storage buckets create gs://$YOUR_BUCKET_NAME-minecraft-backup
   ```

2. Create a backup script:
   ```bash
   sudo nano /home/minecraft/backup.sh
   ```

   Add the following content:
   ```bash
   #!/bin/bash
   screen -r mcs -X stuff '/save-all\n/save-off\n'
   /usr/bin/gcloud storage cp -R ${BASH_SOURCE%/*}/world gs://${YOUR_BUCKET_NAME}-minecraft-backup/$(date "+%Y%m%d-%H%M%S")-world
   screen -r mcs -X stuff '/save-on\n'
   ```

3. Make the script executable:
   ```bash
   sudo chmod 755 /home/minecraft/backup.sh
   ```

4. Test the backup script:
   ```bash
   . /home/minecraft/backup.sh
   ```

5. Schedule the backup with cron:
   ```bash
   sudo crontab -e
   ```
   
   Add this line for backups every 4 hours:
   ```
   0 */4 * * * /home/minecraft/backup.sh
   ```

### 6. Server Maintenance

To stop the Minecraft server:
```bash
sudo screen -r -X stuff '/stop\n'
```

You can then stop the VM instance from the Google Cloud Console.

### 7. Automating Startup and Shutdown

For added convenience, you can configure metadata scripts for startup and shutdown:

1. Edit the VM instance
2. Add the following metadata:
   - Key: `startup-script-url`, Value: `https://storage.googleapis.com/cloud-training/archinfra/mcserver/startup.sh`
   - Key: `shutdown-script-url`, Value: `https://storage.googleapis.com/cloud-training/archinfra/mcserver/shutdown.sh`

## Script Files

This repository includes the following scripts:
- `backup.sh`: Automated backup script
- `startup.sh`: Custom startup script (local version of the cloud script)
- `shutdown.sh`: Custom shutdown script (local version of the cloud script)

## Monitoring & Management

- Server status can be checked using [Minecraft Server Status](https://mcsrvstat.us/) or similar tools
- Regular backups are stored in your Cloud Storage bucket

## Cost Considerations

- The VM will incur charges when running
- The persistent disk will incur storage charges
- Cloud Storage will incur charges for backup storage
- Consider setting up Object Lifecycle Management in Cloud Storage to manage backup retention

## License

This project is provided as-is under the MIT License. The Minecraft server software is subject to Mojang's EULA.

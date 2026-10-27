#!/bin/bash

# ==============================================================================
# Ubuntu Automated Backup Script
# ==============================================================================

# Configuration
SOURCE_DIRS=("/home/ubuntu/documents" "/etc" "/var/www")  # Directories to back up
BACKUP_DIR="/mnt/backup"                                  # Destination directory / mount point
RETENTION_DAYS=30                                         # Days to retain old backups
LOG_FILE="/var/log/system_backup.log"                     # Log file location
DATE=$(date +%Y-%m-%d_%H%M%S)
BACKUP_PATH="$BACKUP_DIR/backup_$DATE"

# Logging function
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_message "Starting system backup..."

# Ensure destination directory exists
if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
fi

# Create a tar.gz archive for the specified directories
ARCHIVE_NAME="$BACKUP_DIR/backup_$DATE.tar.gz"

log_message "Creating archive $ARCHIVE_NAME..."

tar -czf "$ARCHIVE_NAME" "${SOURCE_DIRS[@]}" 2>> "$LOG_FILE"

if [ $? -eq 0 ]; then
    log_message "Backup created successfully: $ARCHIVE_NAME"
else
    log_message "ERROR: Backup encountered issues. Check $LOG_FILE for details."
    exit 1
fi

# Rotate / Delete backups older than RETENTION_DAYS
log_message "Cleaning up backups older than $RETENTION_DAYS days..."
find "$BACKUP_DIR" -type f -name "backup_*.tar.gz" -mtime +$RETENTION_DAYS -exec rm -f {} \; -exec log_message "Removed old backup: {}" \;

log_message "Backup completed."

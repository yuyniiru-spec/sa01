# ==============================================================================
# Windows Automated Backup Script
# ==============================================================================

# Configuration Settings
$SourcePaths = @("C:\Users\YourUsername\Documents", "C:\Users\YourUsername\Projects") # Paths to backup
$BackupDestination = "D:\Backups"                                                       # Destination drive/folder
$RetentionDays = 30                                                                    # Keep backups for X days
$LogFile = "C:\Scripts\backup_log.txt"                                                 # Log file location

# Create timestamp and backup filename
$Timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
$ZipFileName = "Backup_$Timestamp.zip"
$ZipFilePath = Join-Path -Path $BackupDestination -ChildPath $ZipFileName

# Ensure destination and log directories exist
if (-not (Test-Path -Path $BackupDestination)) {
    New-Item -ItemType Directory -Path $BackupDestination -Force | Out-Null
}

Function Write-Log {
    Param ([string]$Message)
    $FormattedMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
    Write-Output $FormattedMessage
    Add-Content -Path $LogFile -Value $FormattedMessage
}

Write-Log "Starting backup process..."

try {
    # Temporary staging folder to aggregate source files
    $StagingPath = Join-Path -Path $env:TEMP -ChildPath "BackupStaging_$Timestamp"
    New-Item -ItemType Directory -Path $StagingPath -Force | Out-Null

    # Copy files to staging folder
    foreach ($Source in $SourcePaths) {
        if (Test-Path -Path $Source) {
            $FolderName = Split-Path -Path $Source -Leaf
            $Dest = Join-Path -Path $StagingPath -ChildPath $FolderName
            Copy-Item -Path $Source -Destination $Dest -Recurse -Force
            Write-Log "Copied $Source to staging."
        } else {
            Write-Log "WARNING: Source directory $Source does not exist."
        }
    }

    # Compress staging folder into ZIP
    Write-Log "Compressing files into $ZipFilePath..."
    Compress-Archive -Path "$StagingPath\*" -DestinationPath $ZipFilePath -CompressionLevel Optimal

    # Clean up staging folder
    Remove-Item -Path $StagingPath -Recurse -Force
    Write-Log "Backup successfully created at $ZipFilePath"

} catch {
    Write-Log "ERROR: Backup failed! Details: $_"
    exit 1
}

# Purge old backups older than $RetentionDays
Write-Log "Cleaning up backups older than $RetentionDays days..."
$CutoffDate = (Get-Date).AddDays(-$RetentionDays)
Get-ChildItem -Path $BackupDestination -Filter "Backup_*.zip" | Where-Object { $_.LastWriteTime -lt $CutoffDate } | ForEach-Object {
    Remove-Item -Path $_.FullName -Force
    Write-Log "Deleted old backup: $($_.Name)"
}

Write-Log "Backup process finished."

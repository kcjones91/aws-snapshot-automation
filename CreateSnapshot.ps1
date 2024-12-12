param(
    [string]$VolumeId,
    [string]$SnapshotName,
    [string]$Description
)

# Validate Inputs
if (-not $VolumeId -or -not $SnapshotName -or -not $Description) {
    Write-Output "Usage: .\CreateSnapshot.ps1 -VolumeId <VolumeId> -SnapshotName <Name> -Description <Description>"
    exit 1
}

# Take Snapshot
Write-Output "Creating snapshot for volume ID: $VolumeId with description: '$Description'..."
try {
    $snapshot = New-EC2Snapshot -VolumeId $VolumeId -Description $Description
    
    if ($null -eq $snapshot) {
        Write-Output "Failed to create snapshot. Please check the volume ID and permissions."
        exit 1
    }
    
    $snapshotId = $snapshot.SnapshotId
    Write-Output "Snapshot created successfully with ID: $snapshotId"
} catch {
    Write-Output "Error creating snapshot: $_"
    exit 1
}

# Monitor Snapshot Progress
Write-Output "Monitoring progress of snapshot: $snapshotId..."
try {
    do {
        Start-Sleep -Seconds 5

        $SnapshotStatus = Get-EC2Snapshot -SnapshotId $snapshotId
        $Progress = $SnapshotStatus.Progress
        $State = $SnapshotStatus.State

        Write-Output "Snapshot Progress: $Progress, State: $State"
    } while ($State -ne "completed")
    
    Write-Output "Snapshot $snapshotId completed successfully!"
} catch {
    Write-Output "Error monitoring snapshot: $_"
    exit 1
}

# Get Instance Attached to the Volume
Write-Output "Retrieving the EC2 instance associated with the volume ID: $VolumeId..."
try {
    $Volume = Get-EC2Volume -VolumeId $VolumeId
    $InstanceId = $Volume.Attachments[0].InstanceId

    if (-not $InstanceId) {
        Write-Output "No EC2 instance found attached to the volume."
    } else {
        Write-Output "EC2 instance ID associated with the volume: $InstanceId"
    }
} catch {
    Write-Output "Error retrieving instance details: $_"
    exit 1
}

# Copy Tags from Instance to Snapshot
if ($InstanceId) {
    Write-Output "Retrieving tags from EC2 instance: $InstanceId..."
    try {
        $InstanceTags = Get-EC2Tag -Filter @{Name="resource-id"; Values=$InstanceId}

        if ($InstanceTags) {
            Write-Output "Copying tags from instance to snapshot..."
            foreach ($Tag in $InstanceTags) {
                New-EC2Tag -Resource $snapshotId -Tags @{Key=$Tag.Key; Value=$Tag.Value}
            }
            Write-Output "Tags copied successfully from instance to snapshot."
        } else {
            Write-Output "No tags found on the instance to copy."
        }
    } catch {
        Write-Output "Error copying tags: $_"
        exit 1
    }
}

# Add Snapshot Name Tag
Write-Output "Adding Name tag to snapshot: $snapshotId..."
try {
    New-EC2Tag -Resource $snapshotId -Tags @{Key="Name";Value=$SnapshotName}
    Write-Output "Name tag added successfully: Name = $SnapshotName"
} catch {
    Write-Output "Error adding Name tag: $_"
    exit 1
}

# Final Confirmation
Write-Output "Snapshot ID: $snapshotId, Description: '$Description', Tag: 'Name=$SnapshotName'"

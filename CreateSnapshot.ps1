param(
    [string]$InstanceIP,
    [string]$VolumeId,
    [string]$SnapshotName,
    [string]$Description
)

# Validate Inputs
if (-not $SnapshotName -or -not $Description) {
    Write-Output "Usage: .\CreateSnapshot.ps1 -SnapshotName <Name> -Description <Description> [-InstanceIP <IP Address>] [-VolumeId <VolumeId>]"
    exit 1
}

if (-not $InstanceIP -and -not $VolumeId) {
    Write-Output "You must provide either -InstanceIP or -VolumeId."
    exit 1
}

# Initialize summary list
$SnapshotSummary = @()

# Snapshot a Single Volume
if ($VolumeId) {
    Write-Output "Creating snapshot for volume ID: $VolumeId with description: '$Description'..."
    try {
        $Snapshot = New-EC2Snapshot -VolumeId $VolumeId -Description $Description

        if ($null -eq $Snapshot) {
            Write-Output "Failed to create snapshot for volume: $VolumeId."
            exit 1
        }

        $SnapshotId = $Snapshot.SnapshotId
        Write-Output "Snapshot created successfully for volume $VolumeId with ID: $SnapshotId"

        # Monitor Snapshot Progress
        Write-Output "Monitoring progress of snapshot: $SnapshotId..."
        do {
            Start-Sleep -Seconds 5
            $SnapshotStatus = Get-EC2Snapshot -SnapshotId $SnapshotId
            $Progress = $SnapshotStatus.Progress
            $State = $SnapshotStatus.State
            Write-Output "Snapshot Progress: $Progress%, State: $State"
        } while ($State -ne "completed")

        Write-Output "Snapshot $SnapshotId for volume $VolumeId completed successfully!"

        # Add Snapshot Name Tag
        New-EC2Tag -Resource $SnapshotId -Tags @{Key="Name"; Value=$SnapshotName}
        Write-Output "Name tag added to snapshot: $SnapshotName"

        # Add to summary
        $SnapshotSummary += @{
            VolumeId = $VolumeId
            SnapshotId = $SnapshotId
            Status = "Completed"
        }
    } catch {
        Write-Output "Error creating snapshot for volume ${VolumeId}: $_"
    }
    exit 0
}

# Search Instance by IP to Get Attached Volumes
if ($InstanceIP) {
    Write-Output "Searching for EC2 instance with IP address: $InstanceIP..."
    try {
        $Instance = Get-EC2Instance -Filter @{Name="private-ip-address"; Values=$InstanceIP} |
                    Select-Object -ExpandProperty Instances

        if (-not $Instance) {
            Write-Output "No instance found with IP address: $InstanceIP."
            exit 1
        }

        $InstanceId = $Instance.InstanceId
        Write-Output "Found EC2 instance: $InstanceId"

        # Retrieve all attached EBS volumes
        $Volumes = $Instance.BlockDeviceMappings | Where-Object { $_.Ebs.VolumeId } | Select-Object -ExpandProperty Ebs
        if (-not $Volumes) {
            Write-Output "No EBS volumes found attached to the instance."
            exit 1
        }
        Write-Output "Found $($Volumes.Count) attached EBS volumes."
    } catch {
        Write-Output "Error searching for instance: $_"
        exit 1
    }

    # Loop Through Each Volume and Take Snapshots
    foreach ($Volume in $Volumes) {
        $VolumeId = $Volume.VolumeId
        Write-Output "Creating snapshot for volume ID: $VolumeId with description: '$Description'..."
        try {
            $Snapshot = New-EC2Snapshot -VolumeId $VolumeId -Description "$Description - Volume: $VolumeId"

            if ($null -eq $Snapshot) {
                Write-Output "Failed to create snapshot for volume: $VolumeId."
                $SnapshotSummary += @{
                    VolumeId = $VolumeId
                    SnapshotId = "N/A"
                    Status = "Failed"
                }
                continue
            }

            $SnapshotId = $Snapshot.SnapshotId
            Write-Output "Snapshot created successfully for volume $VolumeId with ID: $SnapshotId"

            # Monitor Snapshot Progress
            Write-Output "Monitoring progress of snapshot: $SnapshotId..."
            do {
                Start-Sleep -Seconds 5
                $SnapshotStatus = Get-EC2Snapshot -SnapshotId $SnapshotId
                $Progress = $SnapshotStatus.Progress
                $State = $SnapshotStatus.State
                Write-Output "Snapshot Progress: $Progress%, State: $State"
            } while ($State -ne "completed")

            Write-Output "Snapshot $SnapshotId for volume $VolumeId completed successfully!"

            # Copy Tags from Instance to Snapshot
            Write-Output "Retrieving tags from EC2 instance: $InstanceId..."
            $InstanceTags = Get-EC2Tag -Filter @{Name="resource-id"; Values=$InstanceId}
            if ($InstanceTags) {
                foreach ($Tag in $InstanceTags) {
                    New-EC2Tag -Resource $SnapshotId -Tags @{Key=$Tag.Key; Value=$Tag.Value}
                }
                Write-Output "Tags copied successfully from instance to snapshot $SnapshotId."
            }

            # Add Snapshot Name Tag
            New-EC2Tag -Resource $SnapshotId -Tags @{Key="Name"; Value="$SnapshotName - $VolumeId"}
            Write-Output "Name tag added to snapshot: $SnapshotName - $VolumeId"

            # Add to summary
            $SnapshotSummary += @{
                VolumeId = $VolumeId
                SnapshotId = $SnapshotId
                Status = "Completed"
            }
        } catch {
            Write-Output "Error creating snapshot for volume ${VolumeId}: $_"
            $SnapshotSummary += @{
                VolumeId = $VolumeId
                SnapshotId = "N/A"
                Status = "Failed"
            }
        }
    }

    Write-Output "All snapshots for instance $InstanceId have been completed."
}

# Display Snapshot Summary
Write-Output "`nSnapshot Summary:"
if ($SnapshotSummary.Count -eq 0) {
    Write-Output "No snapshots were created."
} else {
    $SnapshotSummary | ForEach-Object {
        Write-Output "Volume ID: $($_.VolumeId) | Snapshot ID: $($_.SnapshotId) | Status: $($_.Status)"
    }
}

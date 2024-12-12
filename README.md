# AWS EC2 Snapshot Script

This PowerShell script creates a snapshot of an EBS volume, monitors the progress of the snapshot, and applies tags from the associated EC2 instance to the snapshot. Additionally, it explicitly tags the snapshot with a `Name` tag.

## Prerequisites

1. AWS Tools for PowerShell installed on your system.
2. AWS credentials configured using `~/.aws/credentials` or environment variables.
3. PowerShell version 5.1 or newer.

## Script Parameters

- `-VolumeId`: The ID of the EBS volume to snapshot (e.g., `vol-03e50165686709bbc`).
- `-SnapshotName`: A name to assign to the snapshot.
- `-Description`: A description of the snapshot.

## Usage

Run the script with the required parameters:

```powershell
.\CreateSnapshot.ps1 -VolumeId "<VolumeId>" -SnapshotName "<SnapshotName>" -Description "<Description>"
```

### Example:

```powershell
.\CreateSnapshot.ps1 -VolumeId "vol-03e50165686709bbc" -SnapshotName "MySnapshot" -Description "Testing Snapshot"
```

## Script Workflow

1. **Snapshot Creation**: The script creates a snapshot of the specified EBS volume.
2. **Progress Monitoring**: The script monitors the progress of the snapshot until completion.
3. **Tag Retrieval**: Tags from the associated EC2 instance (if any) are retrieved.
4. **Tag Application**: Tags are applied to the snapshot, including an explicit `Name` tag.

## Expected Output

```plaintext
Validating input types...
Type of VolumeId: String
Type of Description: String
Creating snapshot for volume ID: vol-03e50165686709bbc with description: 'Testing Snapshot'...
Snapshot created successfully with ID: snap-0abcd1234efgh5678
Monitoring progress of snapshot: snap-0abcd1234efgh5678...
Snapshot Progress: 29%, State: pending
Snapshot Progress: 100%, State: completed
Snapshot snap-0abcd1234efgh5678 completed successfully!
Retrieving the EC2 instance associated with the volume ID: vol-03e50165686709bbc...
EC2 instance ID associated with the volume: i-0abcd1234efgh5678
Retrieving tags from EC2 instance: i-0abcd1234efgh5678...
Copying tags from instance to snapshot...
Tags copied successfully from instance to snapshot.
Adding Name tag to snapshot: snap-0abcd1234efgh5678...
Name tag added successfully: Name = MySnapshot
Snapshot ID: snap-0abcd1234efgh5678, Description: 'Testing Snapshot', Tag: 'Name=MySnapshot'
```

## Error Handling

- The script gracefully handles errors during snapshot creation, progress monitoring, or tag application.
- Informative error messages are provided to help troubleshoot issues.

## Notes

- Ensure the volume is attached to an EC2 instance if you want to copy its tags.
- The `Get-EC2Tag` cmdlet is used to retrieve tags associated with the EC2 instance.

## Licensing

This script is provided as-is without any warranties. Use at your own risk.

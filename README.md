
# AWS EC2 Snapshot Script

This PowerShell script automates the creation of snapshots for AWS EC2 volumes. It allows users to create snapshots either for a specific volume or for all volumes attached to an EC2 instance identified by its private IP address.

## Features

- Create snapshots for a specific volume by providing the Volume ID.
- Create snapshots for all volumes attached to an EC2 instance by providing the Instance IP.
- Monitors the progress of each snapshot until completion.
- Copies tags from the EC2 instance to the snapshot.
- Adds a user-defined `Name` tag to each snapshot.
- Displays a clear summary of all snapshots created.

## Usage

### Prerequisites

1. AWS Tools for PowerShell must be installed.
   ```powershell
   Install-Module -Name AWS.Tools.EC2 -Scope CurrentUser
   ```
2. AWS credentials must be configured.
   ```powershell
   Initialize-AWSDefaultConfiguration -ProfileName <ProfileName> -Region <Region>
   ```

### Script Parameters

- `-InstanceIP` (optional): Private IP address of the EC2 instance whose volumes you want to snapshot.
- `-VolumeId` (optional): Volume ID of the specific volume you want to snapshot.
- `-SnapshotName` (required): The name to assign to the snapshot.
- `-Description` (required): Description for the snapshot.

### Examples

#### 1. Create Snapshot for a Specific Volume
```powershell
.\CreateSnapshot.ps1 -VolumeId "vol-03e50165686709bbc" -SnapshotName "MySnapshot" -Description "Snapshot for a single volume"
```

#### 2. Create Snapshots for All Volumes Attached to an Instance
```powershell
.\CreateSnapshot.ps1 -InstanceIP "10.0.0.10" -SnapshotName "MySnapshot" -Description "Snapshots for all attached volumes"
```

### Output

#### Example Output
```plaintext
Snapshot Summary:
Volume ID: vol-07cdd2216ade2b772 | Snapshot ID: snap-0f015a23860b1e308 | Status: Completed
Volume ID: vol-08a167d06b7d90f4d | Snapshot ID: snap-092d83879d80c9946 | Status: Completed
```

## Notes

- If both `-InstanceIP` and `-VolumeId` are provided, the script prioritizes `-VolumeId`.
- Proper error handling ensures that failed snapshots are reported in the summary.
- Make sure the IAM role or user associated with your credentials has permissions for `ec2:DescribeInstances`, `ec2:CreateSnapshot`, and `ec2:CreateTags`.

---

### Latest Run Summary

```plaintext
Snapshot Summary:
Volume ID: vol-07cdd2216ade2b772 | Snapshot ID: snap-0f015a23860b1e308 | Status: Completed
Volume ID: vol-08a167d06b7d90f4d | Snapshot ID: snap-092d83879d80c9946 | Status: Completed
```

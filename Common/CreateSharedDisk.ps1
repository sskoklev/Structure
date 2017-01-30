#########################################################################
# Author: Mark Freeman, CSC
# Description: Create virtual disks and then add/attach them to the relevant VMs
# Updates:
#         2015-03-25 Added logging and exception handling (sskoklev)
#########################################################################

<#
Check what host the VMs are running on. This script must be run on that server.
The host CSCMSVCSC508 maps to 20.154.76.48
The host CSCMSVCSC608 maps to 20.154.76.58


Ensure Template has been renamed to ensure uniqueness across environment before starting this script
Align the folder name with the container/VMs that will utilise the virtual disks.

#>

<# Shared Cluster example parameters

$DBCluster="DBS001_2_ADSandpit"    # ensure this is unique
$DBServer1 = "ADSDBS001-1"         # this is the renamed name  
$DBServer2 = "ADSDBS002-1"         # this is the renamed name
$InstanceCount= 7                  # minus the Witness disk
$location = 4                      # starting scsi location, keep in mind volumes

#>

<# SharePoint Cluster example parameters

$DBCluster="DBS003_4_ADSandpit"    # ensure this is unique
$DBServer1 = "ADSDBS003-1"         # this is the renamed name  
$DBServer2 = "ADSDBS004-1"         # this is the renamed name
$InstanceCount= 7                  # minus the Witness disk
$location = 4                      # starting scsi location, keep in mind volumes

#>

<# Lync Cluster example parameters

$DBCluster="DBS005_6_ADSandpit"    # ensure this is unique
$DBServer1 = "ADSDBS005-1"         # this is the renamed name  
$DBServer2 = "ADSDBS006-1"         # this is the renamed name
$InstanceCount= 3                  # minus the Witness disk
$location = 4                      # starting scsi location, keep in mind volumes

#>

# Copy/pase one of the above sections here. Update folder and template names as reqd.

$DBCluster="DBS001_2_DEV"    # ensure this is unique
$DBServer1 = "DEVDBS001-1"         # this is the renamed name  
$DBServer2 = "DEVDBS002-1"         # this is the renamed name
$InstanceCount= 7                  # minus the Witness disk
$location = 4                      # starting scsi location, keep in mind volumes


$scriptPath = $env:USERPROFILE
. .\LoggingV2.ps1 $true $scriptPath "CreateSharedDisks.ps1"

try
{
    # ensure the VMs are both hosted here
    $currentHost = Get-VMHost 
    $currentHostName = $currentHost.Name
    $host1 = Get-VM $DBServer1 | Select ComputerName
    $host2 = Get-VM $DBServer2 | Select ComputerName

    $validHost = $true
    if (([string]::IsNullOrEmpty($host1)))
    {
        log "$DBServer1 is not currently hosted on $currentHostName"
        $validHost = $false
    }

    if (([string]::IsNullOrEmpty($host2)))
    {
        log "$DBServer2 is not currently hosted on $currentHostName"
        $validHost = $false
    }

    if($host1 -notmatch $host2)
    {
        log "$DBServer1 is hosted on $host1 while $DBServer2 is hosted on $host2."
        $validHost = $false
    }

    if ($validHost -eq $false)
    {
        log "As not all of the VMs are hosted on this VM Host no disks will be created or attached."
        return
    }

    log "INFO: DB Server 1: '$DBServer1', DB Server 2: '$DBServer2', Instance Count: $InstanceCount"

    $Folder = "C:\ClusterStorage\Volume2\SharedDisk\$DBCluster"
    $folderExists = Test-Path $Folder
    if($folderExists -eq $true)
    {
        log "The folder '$Folder' already exists no disks will be created or attached." 
        return
    }

    New-Item $Folder -type directory
    New-VHD -Path “$Folder\Witness.vhdx” -Dynamic -SizeBytes 1GB

    log "INFO: Created Witness Disk: '$Folder\Witness.vhdx'"

    for ($DiskNumber = 1; $DiskNumber -lt ($InstanceCount+1); $DiskNumber++)
    {
        New-VHD -Path “$Folder\Instance$DiskNumber.vhdx” -Dynamic -SizeBytes 10GB
        log "INFO: Created Instance Disk: '$Folder\Instance$DiskNumber.vhdx'"
    }

    Add-VMHardDiskDrive $DBServer1 -ControllerType SCSI -ControllerNumber 0 -ControllerLocation $location -Path “$Folder\Witness.vhdx” -SupportPersistentReservations 
    Add-VMHardDiskDrive $DBServer2 -ControllerType SCSI -ControllerNumber 0 -ControllerLocation $location -Path “$Folder\Witness.vhdx” -SupportPersistentReservations 

    log "INFO: Added Witness Disks: '$Folder\Witness.vhdx' to both DB servers"

    $location = $location+1
    for ($DiskNumber = 1; $DiskNumber -lt ($InstanceCount+1); $DiskNumber++)
    {
        Add-VMHardDiskDrive $DBServer1 -ControllerType SCSI -ControllerNumber 0 -ControllerLocation $location -Path “$Folder\Instance$DiskNumber.vhdx” -SupportPersistentReservations 
        Add-VMHardDiskDrive $DBServer2 -ControllerType SCSI -ControllerNumber 0 -ControllerLocation $location -Path “$Folder\Instance$DiskNumber.vhdx” -SupportPersistentReservations 
        $location = $location+1

        log "INFO: Added Instance Disks: '$Folder\Instance$DiskNumber.vhdx' to both DB servers"
    } 

    log ""
    log ""
    log "INFO: Completed creating and adding shared disks."
}
catch
{
    $ex = $_.Exception | format-list | Out-String
    log "ERROR: Exception occurred `nException Message: $ex"
}

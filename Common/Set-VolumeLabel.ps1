# Set-VolumeLabel.ps1
#########################################################################
# Author: Stiven Skoklevski,
# Rename the disk label.
# Eg of parameter: 
#     $DISKLABELS = "E;Application,F;PageFile,"
# The above example will set Drive E label to Appplication and Drive F label to Pagefile
#########################################################################

if([String]::IsNullOrEmpty($DISKLABELS))
{
   log "The DISKLABELS parameter is null or empty."
}
else
{
    $option = [System.StringSplitOptions]::RemoveEmptyEntries
    $diskSets = $DISKLABELS.Split(',', $option)

    foreach($diskSet in $diskSets)
    {
        $currentDiskSet = $diskSet.Split(';', $option)

        $driveLetter = $currentDiskSet[0]
        $driveLabel = $currentDiskSet[1]

        if([String]::IsNullOrEmpty($driveLetter))
        {
           log "The driveLetter parameter is null or empty."
           continue
        }

        if([String]::IsNullOrEmpty($driveLabel))
        {
           log "The driveLabel parameter is null or empty."
           continue
        }

        $disk = Get-Volume -DriveLetter $driveLetter -ErrorAction SilentlyContinue
        if($disk -ne $null)
        {
            $oldLabel = $disk.FileSystemLabel
            Set-Volume -FileSystemLabel $oldLabel -NewFileSystemLabel  $driveLabel
            log "INFO: Drive $driveLetter was renamed from $oldLabel to $driveLabel."
        }
        else
        {
            log "WARN: Drive $driveLetter could not be found."
        }
    }
}
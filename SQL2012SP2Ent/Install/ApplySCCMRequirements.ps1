Param(
    [string] $scriptPath
)

#########################################################################
# Author: Stiven Skoklevski, CSC
# Apply SCCM requirements
#########################################################################

#########################################################################
# Create NO_SMS file
# This file is required to ensure SCCM does not consider these drives as candidates to install onto
# The shared disks are catered for during the shared disk configuration.
# The non shared disks need to be done during install as this has to be done on all nodes
#########################################################################
function Create_No_SMS_file
{
   log "INFO: ***** Creating NO_SMS_ON_DRIVE files ***********************************************************"

    $drives = Get-PSDrive -PSProvider 'FileSystem'
    if (([string]::IsNullOrEmpty($drives)))
    {
        log "WARN: No drives were found."
        return
    }

    foreach ($drive in $drives) 
    {   
        try
        {  
            $driveLetter = $drive.Root
            $file = "$($driveLetter)NO_SMS_ON_DRIVE.sms"
            log "INFO: Creating file: '$file'"
            $filecreated = New-Item $file -Type file -Force
            if (([string]::IsNullOrEmpty($filecreated)))
            {
                log "WARN: File: '$file' was not created successfully. Confirm it is not a floppy or CD/DVD drive."
            }
            else
            {
                log "INFO: Created file: '$file'"
             }
        }
        catch
        {
            log "Error: Create_No_SMS_file Exception Message: $($_.Exception.Message)"
        }
    }

   log "INFO: ***** Created NO_SMS_ON_DRIVE files ***********************************************************"
}

#########################################################################
# Main
#########################################################################

Set-Location -Path $scriptPath 

. .\LoggingV2.ps1 $true $scriptPath "ApplySCCMRequirements.ps1"

try
{
    log "INFO: ***** Applying SCCM Requirements ***********************************************************"

    Create_No_SMS_file

    log "INFO: ***** Applied SCCM Requirements ***********************************************************"
}
catch
{
    log "Error: Apply SCCM Requirements Exception Message: $($_.Exception.Message)"
}



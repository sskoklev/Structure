Param(
    [string] $scriptPath,
    [string] $enableLicEnforcement,
    [string] $groupStd,
    [string] $groupPrem
)


function Disable-UserLicensing
{
    log "INFO: about to Disable user licensing"
    Disable-SPUserLicensing -Confirm:$false
    $mappings = Get-SPUserLicenseMapping
    foreach($mapping in $mappings)
    {
        log ("INFO: Removing user license mapping " + $mapping.Name)
        $id = $mapping.Identity
        Remove-SPUserLicenseMapping -Identity $id
    }
}

############################################################################################
# Main
# Author: Marina Krynina
############################################################################################

# \USER_PROFILE
#        \Install
#        \Config
#        \InstallMedia
#        \Logs

Set-Location -Path $scriptPath 

 # Logging must be configured here. otherwise it gets lost in the nested calls# 
 . .\LoggingV2.ps1 $true $scriptPath "Configure-License-Enforcement.ps1"
 . .\Config\Configure-SP2013-Functions.ps1

log "INFO: Starting Configuration of Licensing Enforcement"
log "INFO: Current location = $scriptPath"
log "INFO: Flag = $enableLicEnforcement"
log "INFO: Standard group = `"$groupStd`""
log "INFO: Premium group = `"$groupPrem`""

try
{
    log "INFO: Loading SharePoint snpains"
    Load-SharePoint-PowerShell

    if ($enableLicEnforcement -eq $true)
    {
        if ([string]::IsNullOrEmpty($groupPrem))
        {
            throw "ERROR: Premium users group name is null"
        }

        if ([string]::IsNullOrEmpty($groupStd))
        {
            throw "ERROR: Standard users group name is null"
        }

        [string]$licFlag = (Get-SPUserLicensing).Enabled

        if ($licFlag -eq "true")
        {
            log "INFO: User Licensing is Enabled. Disabing before mapping the new groups"
            Disable-UserLicensing
        }

        log "INFO: about to Enable user licensing"
        Enable-SPUserLicensing -Confirm:$false

        log "INFO: Mapping Premium users `"$groupPrem`""
        $ent = New-SPUserLicenseMapping -SecurityGroup $groupPrem -License Enterprise
        Add-SPUserLicenseMapping -Mapping $ent 

        log "INFO: Mapping Standard users `"$groupStd`""
        $std = New-SPUserLicenseMapping -SecurityGroup $groupStd -License Standard
        Add-SPUserLicenseMapping -Mapping $std 

        log "INFO: Mapping Office Web Apps users `"$groupStd`""
        $wac = New-SPUserLicenseMapping -SecurityGroup $groupStd -License OfficeWebAppsEdit
        Add-SPUserLicenseMapping -Mapping $wac 

        log "INFO: Mapping Office Web Apps users `"$groupPrem`""
        $wac = New-SPUserLicenseMapping -SecurityGroup $groupPrem -License OfficeWebAppsEdit
        Add-SPUserLicenseMapping -Mapping $wac

    }
    elseif ($enableLicEnforcement -eq $false)
    {
        log "INFO: about to Disable user licensing"
        Disable-UserLicensing
    }
    else
    {
        log "INFO: User licensing flag is not set."
    }


    log "INFO:: Finished Configuration of License Enforcement"
    return 0
}
catch 
{
    log "ERROR: $($_.Exception.Message)"

    # This is done to get an error code from the scheduled task.
    Write-Output  $($_.Exception.Message) | Out-File "$scriptPath\error.txt" -Append
    throw "ERROR: $($_.Exception.Message)"
}



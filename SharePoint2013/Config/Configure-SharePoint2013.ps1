Param(
    [string] $scriptPath,
    [string] $inputFile,
    [string] $useSSL,
    [string] $clientDomain
)

############################################################################################
# Main
# Author: Marina Krynina
# Updates: 
#         2014-12-17 Configures SharePoint 2013 Farm based on configuration xml file
############################################################################################

# \USER_PROFILE
#        \Install
#        \Config
#        \InstallMedia
#        \Logs

Set-Location -Path $scriptPath 

 # Logging must be configured here. otherwise it gets lost in the nested calls# 
 . .\LoggingV2.ps1 $true $scriptPath "Configure-SharePoint2013.ps1"
 . .\Config\Configure-SP2013-Functions.ps1

$env:spVer = "15"

log "INFO:: Starting SharePoint farm Configuration"
log "Rnning the script under identity of $env:USERDOMAIN\$env:USERNAME"
log "Current location = $scriptPath"
log "Configuration XML = $inputFile"

# Globally update all instances of "localhost" in the input file to actual local server name
if ($useSSL -eq $true)
{
    [xml]$xmlinput = (((Get-Content $inputFile) -replace ("localhost", $env:COMPUTERNAME)) -replace( "http://", "https://"))
}
else
{
    [xml]$xmlinput = ((Get-Content $inputFile) -replace ("localhost", $env:COMPUTERNAME))
}

try
{
    log "*** Running PrepForConfig checks ***"
    PrepForConfig
    log "No issues were found during PrepForConfig, starting configuration.`n"

    log "*** Adding Farm Account to Allow Logon Locally local poicy ***"
    AddFarmAccountToLogonLocally ($xmlinput.Configuration.Farm.Account.Username)
    log "Finished Farm Account to Allow Logon Locally local poicy ***"

    log "*** Resetting FIM Services"
    ResetFIMServices
    log "Finished Resetting FIM Services"

    log "*** Adding SharePoint Powershell snapin ***"
    Load-SharePoint-PowerShell
    log "SharePoint PowerShell Snapin has been loaded.`n"

    log "*** Running Setup-Farm ***"
    Setup-Farm
    log "SharePoit 2013 farm has been setup, starting configuration of Service Applications.`n"

    try
    {
        log "*** Export-import SharePOint Root certificate to the Trusted Root store to avoid error event id 8321 ***"
        CopySharePointRootCertToLocalTrustedCertStore
        log "Finished Export-import SharePOint Root certificate to the Trusted Root store to avoid error event id 8321 ***"
    }
    catch
    {
        log "WARNING: Exception occurred in CopySharePointRootCertToLocalTrustedCertStore $($_.Exception.Message)"
    }

    log "*** Setting up Service Applications ***"
    Setup-Services
    log "Service Applications have been setup.`n"

    # Configuration of User Profiles and Finalize-Install are done in the User profile script

    log "INFO:: Finished SharePoint farm Configuration."
    return 0
}
catch 
{
    log "ERROR: $($_.Exception.Message)"

    # This is done to get an error code from the scheduled task.
    Write-Output  $($_.Exception.Message) | Out-File "$scriptPath\error.txt" -Append
    throw "ERROR: $($_.Exception.Message)"
}



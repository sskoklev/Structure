Param(
    [string] $scriptPath,
    [string] $inputFile
)


############################################################################################
# Main
# Author: Marina Krynina
# Desc: Creates sUser Profile Service Application on the local server.
#       Starts User profile Synch Service on a synch server
############################################################################################

# \USER_PROFILE
#        \Install
#        \Config
#        \InstallMedia
#        \Logs

Set-Location -Path $scriptPath 

 # Logging must be configured here. otherwise it gets lost in the nested calls# 
 . .\LoggingV2.ps1 $true $scriptPath "Configure-UserProfiles.ps1"
 . .\Config\Configure-SP2013-Functions.ps1

$env:spVer = "15"

log "INFO:: Starting SharePoint User profiles Configuration"
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
    log "*** Adding SharePoint Powershell snapin ***"
    Load-SharePoint-PowerShell
    log "SharePoint PowerShell Snapin has been loaded.`n"

    log "*** Setting up User Profiles Service Application ***"
    CreateUserProfileServiceApplication([xml]$xmlinput)
    log "User Profiles Service Application have been setup.`n"

    Finalize-Install

    log "INFO:: Finished SharePoint User Profiles Configuration"
    return 0
}
catch 
{
    log "ERROR: $($_.Exception.Message)"

    # This is done to get an error code from the scheduled task.
    Write-Output  $($_.Exception.Message) | Out-File "$scriptPath\error.txt" -Append
    throw "ERROR: $($_.Exception.Message)"
}



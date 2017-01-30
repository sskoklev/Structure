# Script: InstallOWA2013
# Author: Marina Krynina, CSC
#################################################################################################
# \USER_PROFILE
#        \Install
#        \Config
#        \InstallMedia
#        \Logs

try
{
    Write-host "INFO: Starting script execution"
    
    # $scriptPath = $env:USERPROFILE
    $scriptPath = split-path -parent $MyInvocation.MyCommand.Definition   
    $scriptName = $MyInvocation.MyCommand.Name

    . .\LoggingV2.ps1 $true $scriptPath "Install-OWA2013.ps1"
    . .\Install\Install-OWA2013.ps1

    exit 0
}
catch
{
    $ex = $_.Exception | format-list | Out-String
    Write-host "ERROR: Exception occurred `nException Message: $ex"

    exit 1
} 


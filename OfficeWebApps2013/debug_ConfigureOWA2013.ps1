# MWS2R2 - OWA 2013 Configure ##################################################################
# Author: Marina Krynina
#################################################################################################
# \USER_PROFILE
#        \Install
#        \Config
#        \InstallMedia
#                \OWA2013SP1x64
#        \Logs

try
{
    Write-host "INFO: Starting script execution"
    
    # $scriptPath = $env:USERPROFILE
    $scriptPath = split-path -parent $MyInvocation.MyCommand.Definition   
    $scriptName = $MyInvocation.MyCommand.Name

    . .\LoggingV2.ps1 $true $scriptPath "Execute-OWA2013Configuration.ps1"
    . .\Config\Execute-OWA2013Configuration.ps1

    exit 0
}
catch
{
    $ex = $_.Exception | format-list | Out-String
    Write-host "ERROR: Exception occurred `nException Message: $ex"

    exit 1
} 


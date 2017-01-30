# Author: Marina Krynina
try
{
    $scriptPath = split-path -parent $MyInvocation.MyCommand.Definition   

    write-host "INFO: Start Execute-SP2016-Config"

    # Agility Variables - set default
    if ([string]::IsNullOrEmpty($VARIABLES)) 
    { 
        write-host "INFO: VARIABLES file is not set, setting default"
        $VARIABLES = "ConfigFiles\Variables-SP2016-Sandpit.ps1"
    }

    # run script but do not execute installs
    $TEST = $false
    #do not use ELevated Task, just load the script for debugging
    $DEBUG = $true
    . .\Config\Execute-SP2016-Config.ps1 $scriptPath "ServiceApps"

    exit 0
}
catch
{
    $ex = $_.Exception | format-list | Out-String
    write-host "ERROR: Exception occurred `nException Message: $ex"

    exit 1
} 
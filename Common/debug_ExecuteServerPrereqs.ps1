# Author: Marina Krynina
############################################################################################
try
{
    write-host "INFO: Start Execute-CommonBase"

    # get current script location
    $scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
    
     . .\Execute-ServerPrereqs.ps1 $scriptPath
    
    exit 0
}
catch
{
    $ex = $_.Exception | format-list | Out-String
    write-host "ERROR: Exception occurred `nException Message: $ex"

    exit 1
}
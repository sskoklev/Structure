# Author: Marina Krynina

try
{
    $scriptPath = split-path -parent $MyInvocation.MyCommand.Definition   

    write-host "INFO: Start Execute-OfcOnline-RemoveServerFromFarm"

    . .\Config\Execute-OfcOnline-RemoveServerFromFarm.ps1 $scriptPath

    exit 0
}
catch
{
    $ex = $_.Exception | format-list | Out-String
    write-host "ERROR: Exception occurred `nException Message: $ex"

    exit 1
} 
 
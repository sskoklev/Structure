# Author: Marina Krynina
############################################################################################
try
{
    write-host "INFO: Start Execute-AirWatch-Install"

    # get current script location
    $scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
    
   # Agility Variables - set default
    $DEBUG = $true
    $INSTALLSET_XML = "ConfigFiles\AirWatch-Install.xml"
     . .\Install\Execute-AirWatch-Install.ps1 $scriptPath "Reports"
    
    exit 0
}
catch
{
    $ex = $_.Exception | format-list | Out-String
    write-host "ERROR: Exception occurred `nException Message: $ex"

    exit 1
}
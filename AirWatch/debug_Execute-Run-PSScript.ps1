# Author: Marina Krynina
############################################################################################
try
{
    write-host "INFO: Start Execute-AirWatch-Scripts"

    # get current script location
    $scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
    
   # Agility Variables - set default
    $DEBUG = $true
    $SCRIPTS_XML = "ConfigFiles\AW-Scripts.xml"
    
     . .\Install\Execute-Run-PSScript.ps1 $scriptPath
    
    exit 0
}
catch
{
    $ex = $_.Exception | format-list | Out-String
    write-host "ERROR: Exception occurred `nException Message: $ex"

    exit 1
}
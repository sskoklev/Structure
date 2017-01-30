# Author: Marina Krynina
try
{
    $scriptPath = split-path -parent $MyInvocation.MyCommand.Definition   

    write-host "INFO: Start Execute-SP2016-PreReqs-Install"

    # Agility Variables - set default
    if ([string]::IsNullOrEmpty($VARIABLES)) 
    { 
        write-host "INFO: VARIABLES file is not set, setting default"
        $VARIABLES = "ConfigFiles\Variables-SP2016-Sandpit.ps1"
    }

    . .\Install\Execute-SP2016-Install.ps1 $scriptPath

    exit 0
}
catch
{
    $ex = $_.Exception | format-list | Out-String
    write-host "ERROR: Exception occurred `nException Message: $ex"

    exit 1
} 
# Author: Marina Krynina
############################################################################################
Param(
    [string] $scriptPath
)
# Author: Marina Krynina
############################################################################################
Set-Location -Path $scriptPath 
write-host "$scriptPath"

try
{
    write-host "INFO: Start Execute-AirWatch-Install"

    # Agility Variables - set default
    # run the script in DEBUG mode as UI Level of the installer is not set correctly when using a scheduled task.
    # the script will executed under currently logged on user
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
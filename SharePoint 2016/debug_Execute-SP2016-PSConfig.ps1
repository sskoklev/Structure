Param(
    [string] $scriptPath,
    [string] $ver = "2016"
)

# Script: SharePoint 2016 Install
# Author: Marina Krynina
#################################################################################################

try
{
    Write-host "INFO: Starting script execution"
    
    $scriptPath = split-path -parent $MyInvocation.MyCommand.Definition   
    $scriptName = $MyInvocation.MyCommand.Name

    . .\PlatformUtils.ps1
    . .\variables\jp2030-serviceAccounts.ps1 $env $ver

    if ($ver -eq "2013")
    {
        . .\Variables\jp2030-variables-shpt.ps1 $env "" 
    }
    elseif ($ver -eq "2016")
    {
        . .\Variables\jp2030-variables-shpt-2016.ps1 $env ""
    }

    $CONFIG_XML = "SilentConfig.xml"
    . .\Install\Install-SharePoint.ps1 $scriptPath 

    exit 0
}
catch
{
    $ex = $_.Exception | format-list | Out-String
    write-host "ERROR: Exception occurred `nException Message: $ex"

    exit 1
} 
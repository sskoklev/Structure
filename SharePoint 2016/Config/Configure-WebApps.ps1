Param(
    [string] $scriptPath,
    [string] $ver = ""
)

############################################################################################
# Main
# Author: Marina Krynina
############################################################################################

Set-Location -Path $scriptPath 
 # Logging must be configured here. otherwise it gets lost in the nested calls# 
 . .\LoggingV2.ps1 $true $scriptPath "Configure-WebApps.ps1"

# Load Common functions
. .\FilesUtility.ps1
. .\VariableUtility.ps1
. .\PlatformUtils.ps1
. .\LaunchProcess.ps1
. .\Construct-URL.ps1

if ($ver -eq "2013")
{
    . .\Config\Configure-SP2013-Functions.ps1
}
elseif ($ver -eq "2016")
{
    . .\Config\Configure-SP2016-Functions.ps1
}
else
{
    throw "ERROR: Unsupported version $ver"
}

$msg = "Start Create web apps"
log "INFO: Starting $msg"

# *** configuration input file
$inputFile = "$scriptPath\Config\$CONFIG_XML"

UpdateInputFile $inputFile

# *** Configure SharePoint farm
# Globally update all instances of "localhost" in the input file to actual local server name
if ($USE_SSL -eq $true)
{
    [xml]$xmlinput = (((Get-Content $inputFile) -replace ("localhost", $env:COMPUTERNAME)) -replace( "http://", "https://"))
}
else
{
    [xml]$xmlinput = ((Get-Content $inputFile) -replace ("localhost", $env:COMPUTERNAME))
}

try
{
    log "*** Adding SharePoint Powershell snapin ***"
    Load-SharePoint-PowerShell
    log "SharePoint PowerShell Snapin has been loaded.`n"

    log "*** Running CreateWebApplications ***"
    if ($PROVISION_WEB_APPS -eq $true)
    {
        CreateWebApplications $xmlinput
    }

    log "INFO:: Finished CreateWebApplications."
    return 0
}
catch 
{
    log "ERROR: $($_.Exception.Message)"
    throw "ERROR: $($_.Exception.Message)"
}

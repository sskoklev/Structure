Param(
    [string] $scriptPath,
    [string] $inputFile,
    [string] $configOption,
    [string] $VARIABLES
)

############################################################################################
# Main
# Author: Marina Krynina
############################################################################################
Set-Location -Path $scriptPath 

# Load Common functions
. .\FilesUtility.ps1
. .\PlatformUtils.ps1
. .\LaunchProcess.ps1
. .\Construct-URL.ps1

# Logging must be configured here. otherwise it gets lost in the nested calls# 
 . .\LoggingV3.ps1 $true $scriptPath "SP2016-Config.ps1"

try
{
    log "INFO:: Starting SharePoint farm Configuration"
    log "Current location = $scriptPath"
    log "Configuration XML = $inputFile"


    if ([string]::IsNullOrEmpty($VARIABLES) -eq $true)
    {
        throw "ERROR: Variable containing name of the Variables script is empty"
    }

    log ("INFO: VARIABLES = " + $VARIABLES)
    . .\$VARIABLES

    . .\Config\Configure-SP2016-Functions.ps1

    # Globally update all instances of "localhost" in the input file to actual local server name
    if ($USE_SSL -eq $true)
    {
        [xml]$xmlinput = (((Get-Content $inputFile) -replace ("localhost", $env:COMPUTERNAME)) -replace( "http://", "https://"))
    }
    else
    {
        [xml]$xmlinput = ((Get-Content $inputFile) -replace ("localhost", $env:COMPUTERNAME))
    }


    $startDate = get-date
    log "*** Running PrepForConfig checks ***"
    PrepForConfig
    log "No issues were found during PrepForConfig, starting configuration.`n"

    log "*** Adding Farm Account to Allow Logon Locally local poicy ***"
    AddFarmAccountToLogonLocally ($xmlinput.Configuration.Farm.Account.Username)
    log "Finished Farm Account to Allow Logon Locally local poicy ***"

    log "*** Adding SharePoint Powershell snapin ***"
    Load-SharePoint-PowerShell
    log "SharePoint PowerShell Snapin has been loaded.`n"

    if ($configOption -eq "MinRoles")
    {
        log "*** Running Setup-Farm ***"
        Setup-Farm
        log "SharePoit farm has been setup, starting configuration of Service Applications.`n"
    }
    elseif ($configOption -eq "ServiceApps")
    {
        log "*** Setting up Service Applications ***"
        Setup-Services
        log "Service Applications have been setup.`n"
    }
    else
    {
        throw "ERROR: Invalid configuration option $configOption"
    }

    # Configuration of User Profiles and Finalize-Install are done in the User profile script

    log "INFO:: Finished SharePoint farm Configuration."
    $endDate = get-date
    $ts = New-TimeSpan -Start $startDate -End $endDate
    log "TIME: Processing Time  - $ts"
    return 0
}
catch 
{
    log "ERROR: $($_.Exception.Message)"

    # This is done to get an error code from the scheduled task.
    Write-Output  $($_.Exception.Message) | Out-File "$scriptPath\error.txt" -Append
    throw "ERROR: $($_.Exception.Message)"
}



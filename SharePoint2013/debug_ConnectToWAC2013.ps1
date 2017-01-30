# MWS2R2 - ConnectToWAC2013 ##################################################################
# Author: Marina Krynina
#################################################################################################
# \USER_PROFILE
#        \Install
#        \Config
#        \InstallMedia
#                \OWA2013SP1x64
#        \Logs

. .\LaunchProcess.ps1
. .\VariableUtility.ps1
. .\PlatformUtils.ps1
. .\FilesUtility.ps1

try
{
    Write-host "INFO: Starting script execution"
    
    $scriptPath = $env:USERPROFILE
    . .\LoggingV2.ps1 $true $scriptPath "Agility_Connect-ToWAC2013.ps1"

    $user = (Get-VariableValue $ADMIN "agilitydeploy" $true)
    $password = get-serviceAccountPassword -username $user

    log "INFO: Getting variables values or setting defaults if the variables are not populated."
    $WAC_SERVER = (Get-VariableValue $WAC_SERVER "OfficeApps" $false) 
    $WAC_CONNECT = (Get-VariableValue $WAC_CONNECT "false" $false) 

    $domainFull = get-domainname   
    $wacServer = $WAC_SERVER + ".$domainFull"

    if ($WAC_CONNECT -eq $true)
    {
	$process = "$PSHOME\powershell.exe"
    	$argument = "-file $scriptPath\Config\Connect-ToWAC2013.ps1 -scriptPath $scriptPath -wacServer $wacserver"
	log "INFO: Attempting to bind SharePoint farm to $wacServer"
    	$Result = LaunchProcessWithHighestPrivAsUser $process $argument "$domain\$user" $password
    }
    else
    {
        log "INFO: WAC_CONNECT flag is set to false. Skipping."
    }

    exit 0
}
catch
{
    $ex = $_.Exception | format-list | Out-String
    Write-host "ERROR: Exception occurred `nException Message: $ex"

    exit 1
} 
#################################################################################################
# Author: Stiven Skoklevski/Denis Gittard
# Desc:   Functions to support preparation of Windows Users
#################################################################################################

. .\FilesUtility.ps1
. .\VariableUtility.ps1
. .\PlatformUtils.ps1
. .\LaunchProcess.ps1

. .\LoggingV2.ps1 $true $scriptPath "ExecuteWindowsUsers.ps1"

if ((CheckFileExists($WINDOWSUSERS_XML)) -ne $true)
{
    $error = "ERROR: $WINDOWSUSERS_XML does not exist"  
    log $error
    return
}


# $scriptPath = $env:USERPROFILE

$domain = get-domainshortname
$user = (Get-VariableValue $ADMIN "agilitydeploy" $true)
$password = get-serviceAccountPassword -username $user

$process = "$PSHOME\powershell.exe"
$argument = "-file $scriptPath\Configure-WindowsUsersV2.ps1 -scriptPath $scriptPath -WINDOWSUSERS_XML $WINDOWSUSERS_XML ; exit `$LastExitCode"
log "INFO: Calling $process under identity $domain\$user"
log "INFO: Arguments $argument"

try
{
    $Result = LaunchProcessAsUser $process $argument "$domain\$user" $password

    log "INFO: LaunchProcessAsUser result: $Result"

    if ($Result -ne 0)
    {
        throw "ERROR: Configure-WindowsUsersV2 returned $Result. Check the log file for more information"
    }
	
    log "INFO: Finished Execute Windows Userss."
    return 0
}
catch
{
    throw "ERROR: $($_.Exception.Message)"
}
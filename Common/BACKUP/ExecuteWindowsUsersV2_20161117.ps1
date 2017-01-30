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

    log "LaunchProcessAsUser result: $Result"

    # check if error.txt exists. if yes, read it and throw exception
    # This is done to get an error code from the scheduled task.
    $errorFile = "$scriptPath\error.txt"
    if (CheckFileExists($errorFile))
    {
        $error = Get-Content $errorFile
        Remove-Item $errorFile
   
        throw $error
    }
	
    log "INFO: Finished Execute Windows Userss."
    return 0
}
catch
{
    throw "ERROR: $($_.Exception.Message)"
}
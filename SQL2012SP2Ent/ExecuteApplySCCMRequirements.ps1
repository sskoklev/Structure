#################################################################################################
# Author: Stiven Skoklevski
# Desc:   Functions to support preparation of Windows
#################################################################################################

. .\FilesUtility.ps1
. .\VariableUtility.ps1
. .\PlatformUtils.ps1
. .\LaunchProcess.ps1

$scriptPath = $env:USERPROFILE

$domain = get-domainshortname
$user = (Get-VariableValue $ADMIN "agilitydeploy" $true)
$password = get-serviceAccountPassword -username $user

$currentUser = $env:USERNAME

$process = "$PSHOME\powershell.exe"
$argument = "-file $scriptPath\Install\ApplySCCMRequirements.ps1 -scriptPath $scriptPath ; exit `$LastExitCode"
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
	
    log "INFO: Finished Execute Windows Cluster."
    return 0
}
catch
{
    throw "ERROR: $($_.Exception.Message)"
}
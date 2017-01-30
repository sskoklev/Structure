############################################################################################
# Author: Stiven Skoklevski
# Desc: Launch post SQL installation configuration tasks as admin
# Updates: 
############################################################################################

# Load Common functions
. .\FilesUtility.ps1
. .\UsersUtility.ps1
. .\VariableUtility.ps1
. .\PlatformUtils.ps1
. .\LaunchProcess.ps1

############################################################################################
# Main
############################################################################################


$msg = "Configuring SQL"
log "INFO: Starting $msg"
log "INFO: Getting variables values or setting defaults if the variables are not populated."

# *** setup account 
$domain = get-domainshortname
$user = (Get-VariableValue $ADMIN "agilitydeploy" $true)
$password = get-serviceAccountPassword -username $user

$scriptPath = $env:USERPROFILE
#$scriptPath = 'C:\Users\skoklevski'

$domain = get-domainshortname
$user = (Get-VariableValue $ADMIN "agilitydeploy" $true)
$password = get-serviceAccountPassword -username $user

$currentUser = $env:USERNAME

$process = "$PSHOME\powershell.exe"
$argument = "-file $scriptPath\Config\Configure-SQL.ps1 ` 
                -scriptPath $scriptPath ` 
                -domain $domain ` 
                -SQLUSERSXMLFILE $SQLUSERSXMLFILE ` 
                -SQLMEMORYXMLFILE $SQLMEMORYXMLFILE ` 
                -SQLPORTSXMLFILE $SQLPORTSXMLFILE ` 
                -SQLCOMPATIBILITYXMLFILE $SQLCOMPATIBILITYXMLFILE ` 
                -GENERICSERVICEXMLFILE $GENERICSERVICEXMLFILE ` 
                ; exit `$LastExitCode"

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
	
    log "INFO: Finished Configure SQL."
    return 0
}
catch
{
    log "ERROR: $($_.Exception.Message)"
    throw "ERROR: $($_.Exception.Message)"
    exit 1
}

    
log "INFO: Finished $msg."
exit 0

Param(
    [string] $scriptPath
)


#################################################################################################
# Author: Marina Krynina
# Desc:   Functions to support configuration of one-way truct and people picker
#################################################################################################

function CheckForError
{
    # check if error.txt exists. if yes, read it and throw exception
    # This is done to get an error code from the scheduled task.
    $errorFile = "$scriptPath\error.txt"
    if (CheckFileExists($errorFile))
    {
        $error = Get-Content $errorFile
        Remove-Item $errorFile
   
        throw $error
    }
}

############################################################################################
# Main
# Author: Marina Krynina
############################################################################################

# Load Common functions
. .\FilesUtility.ps1
. .\PlatformUtils.ps1
. .\LaunchProcess.ps1

Set-Location -Path $scriptPath 

$msg = "Start one-way trust, people picker configuration"
log "INFO: Starting $msg"

# *** setup account 
$domain = get-domainshortname
$domainFull = get-domainname
$user = (Get-VariableValue $ADMIN "agilitydeploy" $true)
$password = get-serviceAccountPassword -username $user
    

# *** Configure SharePoint farm
$process = "$PSHOME\powershell.exe"
try
{
    # Farm Configuration
    $argument = "-file $scriptPath\Config\Configure-SharePoint2013.ps1 -scriptPath $scriptPath -inputFile $inputFile -useSSL $useSSL; exit `$LastExitCode"
    log "INFO: Calling $process under identity $domain\$user"
    log "INFO: Arguments $argument"

    # It is assumed the SSL certificates have been imported in the separate script
    $Result = LaunchProcessWithHighestPrivAsUser $process $argument "$domain\$user" $password

    # DEBUG
    # . .\Config\Configure-SharePoint2013.ps1 $scriptPath $inputFile
    
    CheckForError

    # there is no need to check if UP needs to be provisioned as it will be taken care of late in the config script
    # User Profiles
    $argument = "-file $scriptPath\Config\Configure-UserProfiles.ps1 -scriptPath $scriptPath -inputFile $inputFile -useSSL $useSSL; exit `$LastExitCode"
    log "INFO: Calling $process under identity $domain\$farmAccount"
    log "INFO: Arguments $argument"

    # Create UPSA under farm account. Otherwise it doesn't work
    $farmAccount = $FARM_ACCOUNT
    $farmPassword = (get-serviceAccountPassword -username $FARM_ACCOUNT)      
    $Result = LaunchProcessWithHighestPrivAsUser $process $argument "$domain\$farmAccount" $farmPassword

    # DEBUG
    # . .\Config\Configure-UserProfiles.ps1 $scriptPath $inputFile
    
    CheckForError
	
    log "INFO: Finished $msg."
    return 0
}
catch
{
    throw "ERROR: $($_.Exception.Message)"
}
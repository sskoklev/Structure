Param(
    [string] $scriptPath
)


#################################################################################################
# Author: Marina Krynina
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
############################################################################################
# Load Common functions
. .\FilesUtility.ps1
. .\VariableUtility.ps1
. .\PlatformUtils.ps1
. .\LaunchProcess.ps1

Set-Location -Path $scriptPath 

$msg = "Start Creating SQL Aliases"
log "INFO: Starting $msg"

# *** setup account 
$domain = get-domainshortname
$domainFull = get-domainname
$user = (Get-VariableValue $ADMIN "agilitydeploy" $true)
$password = get-serviceAccountPassword -username $user


[string]$configFileName = (Get-VariableValue $SQLALIAS_XML "\Config\sqlAlias.xml" $true)
if ($configFilename.StartsWith("\") -eq $false)
{
    $configFilename = "\" + $configFilename
}

$sqlAliasConfigXml = ($scriptPath + $configFilename)
if ((CheckFileExists( $sqlAliasConfigXml)) -ne $true)
{
    throw "ERROR: Config $sqlAliasConfigXml file is missing. Nothing to process."
}


$process = "$PSHOME\powershell.exe"
try
{
    $argument = "-file $scriptPath\Create-SQLAlias.ps1 -scriptPath $scriptPath -sqlAliasConfigXml $sqlAliasConfigXml ; exit `$LastExitCode"

    log "INFO: Calling $process under identity $domain\$user"
    log "INFO: Arguments $argument"

    $Result = LaunchProcessWithHighestPrivAsUser $process $argument "$domain\$user" $password

    # DEBUG
    # . .\Create-SQLAlias.ps1 $scriptPath $sqlAliasConfigXml
    
    CheckForError

    log "INFO: Result $Result"
    log "INFO: Finished $msg."
    return 0
}
catch
{
    throw "ERROR: $($_.Exception.Message)"
}
Param(
    [string] $scriptPath
)

############################################################################################
# Author: Marina Krynina
# Desc: Executes Unit testing Server Side - Common
############################################################################################

# \USER_PROFILE
#        \TestResults

# Load Common functions
. .\PlatformUtils.ps1
. .\LaunchProcess.ps1
. .\VariableUtility.ps1
. .\FilesUtility.ps1


try
{
    log "INFO: Start Unit Testing"

    # *** setup account 
    $domain = get-domainshortname
    $domainFull = get-domainname
    $user = (Get-VariableValue $ADMIN "agilitydeploy" $true)
    $password = get-serviceAccountPassword -username $user
    
    $testFolder = ([string](Get-VariableValue $TESTFRAMEWORKFOLDER "TestFramework" $true))
    $scripts = ([string](Get-VariableValue $TESTSCRIPTS "UnitTest-Server-Common.ps1" $true)).Split(";")
    log "INFO: To execute $scripts"

    $process = "$PSHOME\powershell.exe"

    foreach($script in $scripts)
    {
        $argument = "-file $scriptPath\$testFolder\$script -scriptPath $scriptPath -testFolder $testFolder ; exit `$LastExitCode"
        log "INFO: Calling $process under identity $domain\$user with arguments Arguments $argument"
        $Result = LaunchProcessWithHighestPrivAsUser $process $argument "$domain\$user" $password

        # DEBUG
        # . .\$testFolder\UnitTest-Server-Common.ps1 -scriptPath $scriptPath -testFolder $testFolder

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

    log "INFO: Finished Unit Testing"
    return 0
}
catch
{
    throw "ERROR: $($_.Exception.Message)"
}
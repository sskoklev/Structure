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
    log "INFO: Start Execute License Enforcement"

    # *** setup account 
    $domain = get-domainshortname
    $domainFull = get-domainname
    $user = (Get-VariableValue $ADMIN "agilitydeploy" $true)
    $password = get-serviceAccountPassword -username $user
    

    $enableLicEnforcement = ([string](Get-VariableValue $ENABLE_LIC_ENFORCEMENT "true" $true))
    $groupStd = (Get-VariableValue $STANDARD_USERS "MyWorkStyle SharePoint Standard" $true)
    $groupPrem = (Get-VariableValue $PREMIUM_USERS "MyWorkStyle SharePoint Premium" $true)

    $process = "$PSHOME\powershell.exe"

    $argument = "-file $scriptPath\Config\Configure-LicenseEnforcement.ps1 -scriptPath $scriptPath -enableLicEnforcement $enableLicEnforcement -groupStd `"$groupStd`" -groupPrem `"$groupPrem`" ; exit `$LastExitCode"
    log "INFO: Calling $process under identity $domain\$user"
    log "INFO: Arguments $argument"

    # It is assumed the SSL certificates have been imported in the separate script
    $Result = LaunchProcessWithHighestPrivAsUser $process $argument "$domain\$user" $password

    # DEBUG
    #. .\Config\Configure-LicenseEnforcement.ps1 $scriptPath -enableLicEnforcement $enableLicEnforcement -groupStd $groupStd -groupPrem $groupPrem
    
    # check if error.txt exists. if yes, read it and throw exception
    # This is done to get an error code from the scheduled task.

    $errorFile = "$scriptPath\error.txt"
    if (CheckFileExists($errorFile))
    {
        $error = Get-Content $errorFile
        Remove-Item $errorFile
   
        throw $error
    }

    log "INFO: Finished Execute License Enforcement"
    return 0
}
catch
{
    throw "ERROR: $($_.Exception.Message)"
}
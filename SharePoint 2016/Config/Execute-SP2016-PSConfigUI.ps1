Param(
    [string] $scriptPath
)

# Script: Run PSCONFIGUI
# Author: Marina Krynina


Set-Location -Path $scriptPath 

# Load Common functions
. .\PlatformUtils.ps1
. .\LaunchProcess.ps1

. .\LoggingV3.ps1 $true $scriptPath "Execute-SP2016-PSConfigUI.ps1"

try
{
    if ([string]::IsNullOrEmpty($VARIABLES) -eq $true)
    {
        throw "ERROR: Variable containing name of the Variables script is empty"
    }

    log ("INFO: VARIABLES = " + $VARIABLES)
    . .\$VARIABLES

    . .\Config\Configure-SP2016-Functions.ps1

    $msg = "Start PSCONFIGUI"
    log "INFO: Starting $msg"

    $domain = get-domainshortname
    $domainFull = get-domainname
    
    $process = "$PSHOME\powershell.exe"
    $argument = "-file $scriptPath\Config\SP2016-PSConfigUI.ps1 -scriptPath $scriptPath ; exit `$LastExitCode"

    $configAccount = $ADMIN
    $configAccountPassword = (get-serviceAccountPassword -username $configAccount)

    log "INFO: Calling $process under identity $domain\$configAccount"
    log "INFO: Arguments $argument"
 
    if ($TEST -ne $true)
    {
        if ($DEBUG -ne $true)
        {
            $Result = LaunchProcessWithHighestPrivAsUser $process $argument "$domain\$configAccount" $configAccountPassword
        }
        else
        {
            $Result = 0
            . .\Config\SP2016-PSConfigUI.ps1 $scriptPath $inputFile $configOption $VARIABLES 
        }
    }

    log "INFO: Exit Code $Result"

    if ($Result -ne 0)
    {
        throw "ERROR: Exit Code = $Result"
    }
    
    log "INFO: Finished $msg."
    return 0
}
catch
{
    throw "ERROR: $($_.Exception.Message)"
}

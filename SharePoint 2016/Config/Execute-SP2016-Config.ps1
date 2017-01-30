Param(
    [string] $scriptPath,
    [string] $configOption
)

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

#################################################################################################
# Author: Marina Krynina
# Desc:   Functions to support SharePoint 2016 farm configuration
#################################################################################################

Set-Location -Path $scriptPath 

# Load Common functions
. .\FilesUtility.ps1
. .\PlatformUtils.ps1
. .\LaunchProcess.ps1
. .\Construct-URL.ps1
. .\VariableUtility.ps1

. .\LoggingV3.ps1 $true $scriptPath "Execute-SP2016-Config.ps1"

try
{
    if ([string]::IsNullOrEmpty($VARIABLES) -eq $true)
    {
        throw "ERROR: Variable containing name of the Variables script is empty"
    }

    log ("INFO: VARIABLES = " + $VARIABLES)
    . .\$VARIABLES

    . .\Config\Configure-SP2016-Functions.ps1

    # *** Configure SharePoint farm
    $msg = "Start SharePoint farm configuration"
    log "INFO: Starting $msg"

    log ("INFO: Server Role = " + $SERVER_ROLE)

    # *** configuration input file
    $inputFile = (Join-Path $scriptPath $CONFIG_XML)
    $webAppsInputFile = (Join-Path $scriptPath $WEBAPPS_CONFIG_XML)
    
    UpdateInputFile $inputFile
    ImportWebAppsXmlToFarmConfigXml $inputFile $webAppsInputFile

    #################################################################################################################
    # Farm Configuration
    #################################################################################################################
    $domain = get-domainshortname
    $domainFull = get-domainname
    
    $process = "$PSHOME\powershell.exe"
    $argument = "-file $scriptPath\Config\SP2016-Config.ps1 -scriptPath $scriptPath -inputFile $inputFile -configOption $configOption -VARIABLES $VARIABLES ; exit `$LastExitCode"

    $configAccount = $FARM_ACCOUNT
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
            . .\Config\SP2016-Config.ps1 $scriptPath $inputFile $configOption $VARIABLES 
        }
    }

    CheckForError

    
    log "INFO: Finished $msg."
    return 0
}
catch
{
    throw "ERROR: $($_.Exception.Message)"
}
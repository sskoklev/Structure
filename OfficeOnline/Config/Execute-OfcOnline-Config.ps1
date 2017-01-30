Param(
    [string] $scriptPath
)

# Office Online Config
# Author: Marina Krynina
############################################################################################
function UpdateInputFile ([string] $inputFile)
{
    if ((ifFileExists( $inputFile)) -ne $true)
    {
        throw "ERROR: $inputFile is missing"
    }

    CreateBackupCopy $inputFile
    [xml]$xmlinput = [xml](Get-Content $inputFile)

    log "INFO: Getting variables values or setting defaults if the variables are not populated."

    log "INFO: Setting SSL flag"
    $xmlinput.Configuration.UseSSL = $USE_SSL

    log "INFO: Setting EditingEnabled flag"
    $xmlinput.Configuration.EditingEnabled = $EDITING_ENABLED

    log "INFO: Setting SSLOffloaded flag"
    $xmlinput.Configuration.SSLOffloaded = $SSLOFFLOADED

    log "INFO: Setting WAC Primary server"
    $xmlinput.Configuration.PrimaryServer = ([string](Get-ServerName $PRIMARY_SERVER)).ToUpper()    

    log "INFO: Setting CacheLocation"
    $xmlinput.Configuration.CacheLocation = $CACHE_LOCATION
    
    log "INFO: Setting CertificateName"
    $xmlinput.Configuration.CertificateName = $CERTIFICATE_NAME

    log "INFO: Setting ExternalURL"
    $xmlinput.Configuration.ExternalURL = (ConstructURL $EXTERNAL_URL "" $USE_SSL)
    
    log "INFO: Setting InternalURL"
    $xmlinput.Configuration.InternalURL = (ConstructURL $INTERNAL_URL "" $USE_SSL)
    
    log "INFO: Setting LogLocation"
    $xmlinput.Configuration.LogLocation = $LOG_LOCATION
    
    log "INFO: Setting RenderingLocalCacheLocation"
    $xmlinput.Configuration.RenderingLocalCacheLocation = $RENDERING_CACHE_LOCATION
    
    # *** update INPUT xml with the values from variables, like server name, domain, etc
    log "INFO: Saving config file with new values"
    $xmlinput.Save($inputFile)
}



############################################################################################
# Main
# Author: Marina Krynina
############################################################################################
Set-Location -Path $scriptPath 

# Load Common functions
. .\FilesUtility.ps1
. .\LaunchProcess.ps1
. .\Construct-URL.ps1
. .\PlatformUtils.ps1

 . .\LoggingV3.ps1 $true $scriptPath "Execute-OfcOnline-Config.ps1"

try
{
    if ([string]::IsNullOrEmpty($VARIABLES) -eq $true)
    {
        throw "ERROR: Variable containing name of the Variables script is empty"
    }

    log ("INFO: VARIABLES = " + $VARIABLES)
    . .\$VARIABLES

    $msg = "Start OfficeOnline farm configuration"
    log "INFO: Starting $msg"

    # *** configuration input file
    $inputFile = (Join-Path $scriptPath $CONFIG_XML)

    UpdateInputFile $inputFile

    $process = "$PSHOME\powershell.exe"
    $argument = "-file $scriptPath\Config\OfcOnline-Config.ps1 -scriptPath $scriptPath -inputFile $inputFile  ; exit `$LastExitCode"

    $domain = get-domainshortname
    $password = get-serviceAccountPassword -username $ADMIN

    log "INFO: domain = $domain, ADMIN = $ADMIN"

    $Result = 0
    if ($DEBUG -ne $true)
    {
        $Result = LaunchProcessWithHighestPrivAsUser $process $argument "$domain\$ADMIN" $password
    }
    else
    {
        . .\Config\OfcOnline-Config.ps1 $scriptPath $inputFile
    }

    log "INFO: Exit Code $Result"

    if ($Result -ne 0)
    {
        throw "ERROR: Exit Code = $Result"
    }
                    
    log "INFO: Finished $msg."
    return $Result
}
catch [Exception]
{
    $ex = $_.Exception | format-list | Out-String
    log "ERROR: Exception occurred `nException Message: $ex"
    throw "ERROR: Exception occurred `nException Message: $ex"
}


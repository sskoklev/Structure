# MWS2R2 - OWA 2013 Configure ##########################################################################################
# Author: Marina Krynina
# Desc:   The script is based on the script provided by ServiceMesh
# Updates: 
#         2015-01-16 Configures OWA farm
############################################################################################
function UpdateInputFile ([string] $inputFile, [string] $password)
{
    if ((ifFileExists( $inputFile)) -ne $true)
    {
        throw "ERROR: $inputFile is missing"
    }

    CreateBackupCopy $inputFile
    [xml]$xmlinput = [xml](Get-Content $inputFile)

    log "INFO: Getting variables values or setting defaults if the variables are not populated."

    log "INFO: Setting SSL flag"
    $xmlinput.Configuration.UseSSL = (Get-VariableValue $USE_SSL "true" $true)     

    log "INFO: Setting WAC Primary server"
    $wacServerPrimary = Get-VariableValue $PRIMARY_SERVER "APP-005" $useHardcodedDefaults
    $xmlinput.Configuration.PrimaryServer = ([string](Get-ServerName $wacServerPrimary)).ToUpper()     

    log "INFO: Setting CacheLocation"
    $xmlinput.Configuration.CacheLocation = Get-VariableValue $CACHE_LOCATION "E:\Program Files\Microsoft\OfficeWebApps\Working\d\" $useHardcodedDefaults
    
    log "INFO: Setting CertificateName"
    $xmlinput.Configuration.CertificateName = Get-VariableValue $CERTIFICATE_NAME “MWS OfficeApps” $useHardcodedDefaults

    log "INFO: Setting ExternalURL"
    $extErl = Get-VariableValue $EXTERNAL_URL "" $useHardcodedDefaults
    $xmlinput.Configuration.ExternalURL = (ConstructURL $extErl "" $useSSL)
    
    log "INFO: Setting InternalURL"
    $intErl = Get-VariableValue $INTERNAL_URL "OfficeApps.mwsaust.net" $useHardcodedDefaults
    $xmlinput.Configuration.InternalURL =  (ConstructURL $intErl "" $useSSL)
    
    log "INFO: Setting LogLocation"
    $xmlinput.Configuration.LogLocation = Get-VariableValue $LOG_LOCATION "L:\OfficeWebApps\Logs\ULS\" $useHardcodedDefaults
    
    log "INFO: Setting RenderingLocalCacheLocation"
    $xmlinput.Configuration.RenderingLocalCacheLocation = Get-VariableValue $RENDERING_CACHE_LOCATION "E:\Program Files\Microsoft\OfficeWebApps\Working\waccache" $useHardcodedDefaults
    
    # *** update INPUT xml with the values from variables, like server name, domain, etc
    log "INFO: Saving config file with new values"
    $xmlinput.Save($inputFile)
}



############################################################################################
# Main
# Author: Marina Krynina
############################################################################################

# \USER_PROFILE
#        \Install
#        \Config
#        \InstallMedia
#        \Logs

# Load Common functions
. .\FilesUtility.ps1
. .\VariableUtility.ps1
. .\PlatformUtils.ps1
. .\LaunchProcess.ps1
. .\Construct-URL.ps1

Set-Location -Path $scriptPath 

$msg = "Start Office Web Apps 2013 farm configuration"
log "INFO: Starting $msg"
log "INFO: Getting variables values or setting defaults if the variables are not populated."

# this is a variable to force hardcoded defaults. It is useful for testing outside of Agility
$useHardcodedDefaults = $false

# *** Determine if we need to use Agility variables or configuration file
$USE_VARIABLES = (Get-VariableValue $USE_VARIABLES $false $true)    

# *** configuration input file
$CONFIG_XML = (Get-VariableValue $CONFIG_XML "MWS2_OWAFarm.xml" $true)    
$inputFile = "$scriptPath\Config\$config_xml"

# *** Use SSL flag
# using custom code to configure SSL, not autoSPInstaller
$useSSL = (Get-VariableValue $USE_SSL "true" $true)    

# *** setup account 
$domain = get-domainshortname
$domainFull = get-domainname
$user = (Get-VariableValue $ADMIN "agilitydeploy" $true)
$password = get-serviceAccountPassword -username $user
       
try
{
    # if Agility variables are not populated, the values will be taken directly from the $CONFIG_XML
    if ($USE_VARIABLES -eq $true)
    { 
        UpdateInputFile $inputFile $password
    }
   
    $process = "$PSHOME\powershell.exe"
    $argument = "-file $scriptPath\Config\Configure-OWA2013.ps1 -scriptPath $scriptPath -inputFile $inputFile"
    $Result = LaunchProcessWithHighestPrivAsUser $process $argument "$domain\$user" $password

    # DEBUG
    #. .\Config\Configure-OWA2013.ps1 $scriptPath $inputFile

    # check if error.txt exists. if yes, read it and throw exception
    # This is done to get an error code from the scheduled task.
    $errorFile = "$scriptPath\error.txt"
    if (CheckFileExists($errorFile))
    {
        $error = Get-Content $errorFile
        Remove-Item $errorFile
   
        throw $error
    }
	
    log "INFO: Finished $msg."
    return 0
}
catch
{
    throw "ERROR: $($_.Exception.Message)"
}


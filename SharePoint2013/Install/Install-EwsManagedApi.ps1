Param(
    [string] $scriptPath
)

############################################################################################
# Main
############################################################################################
# Load Common functions
. .\FilesUtility.ps1
. .\VariableUtility.ps1
. .\PlatformUtils.ps1
. .\LaunchProcess.ps1

Set-Location -Path $scriptPath 

. .\LoggingV2.ps1 $true $scriptPath "Install-EwsManagedApi.ps1"
log "INFO: Installing Exchange Web Service managed API"

# If the Agility variables are not set, values from the configuration file will be used instead
log "INFO: Getting variables values or setting defaults if the variables are not populated."
$installMedia = (Get-VariableValue $INSTALL_MEDIA "InstallMedia" $true) 
$installer = (Get-VariableValue $INSTALLER "\EwsManagedApi\EwsManagedApi.msi" $true) 

$msiExecPath = "c:\windows\system32\msiexec.exe"

$mediaLocation = $scriptPath + "\" + $installMedia + $installer
log "INFO: medialocation = $mediaLocation"

$arguments = "/I $mediaLocation /l* " + $scriptPath + "\logs\EwsManagedApi.log"
log "INFO: arguments = $arguments"
 
# INSTALL 
$result = LaunchProcessAsAdministrator $msiExecPath $arguments
log "INFO: Exchange Web Service managed API Installer returned : $result";

return $result 
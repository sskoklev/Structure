############################################################################################
# Author: Marina Krynina
# Desc:   Functions to support installation of SharePoint 2013 
# Updates:
#          2015-11-12
#################################################################################################


########################################################################################################
# Installs OWA 2013 Binaries
########################################################################################################
function Install-OWA2013Binaries([string] $scriptPath, [string] $mediaLocation, [string] $configFile, [hashtable] $parameters)
{
    # new location of the silent config file
    $targetConfigFile = "$scriptPath\$mediaLocation\files\setupsilent\$configFile"
    $sourceConfigFile = $scriptPath + "\Install\$configFile"

    if ($parameters -eq $null)
    {
        throw "ERROR: paramaters is null"
    }

    # copy config file to the media location
    if (CheckFileExists( $sourceConfigFile))
    {
        Get-Content ( $sourceConfigFile) |% {$_.replace("`n", "`r`n")} | Out-File -filepath $targetConfigFile
    }
    else
    {
        throw "ERROR: $sourceConfigFile does not exist"
    }

    Update-ConfigXML "INSTALLLOCATION" $parameters.Get_Item("INSTALLLOCATION") $sourceConfigFile $targetConfigFile
    Update-ConfigXML "DATADIR" $parameters.Get_Item("DATADIR") $sourceConfigFile $targetConfigFile
    Update-ConfigXML "PIDKEY" $parameters.Get_Item("PIDKEY") $sourceConfigFile $targetConfigFile

    $arguments = "/config " + $targetConfigFile
    $path =  "$scriptPath\$mediaLocation\Setup.exe"

    $result = LaunchProcessAsAdministrator $path $arguments

    return $result
}

#################################################################
# Main
#################################################################
# Load Common functions
. .\FilesUtility.ps1
. .\LaunchProcess.ps1
. .\VariableUtility.ps1

# get current script location
$scriptPath = $env:USERPROFILE

# Folder structure on VM
# C:\Users\InstallerAccount
#            \Install
#            \Config
#            \InstallMedia
#            \Logs


$msg = "Installing OWA Server 2013 binaries"
log "INFO: $msg"

$useHardcodedDefaults = $false

log "INFO: Getting variables values or setting defaults if the variables are not populated."

$configFileName = (Get-VariableValue $CONFIG_XML "OWA_SilentConfig.xml" $true) 
$mediaLocation = (Get-VariableValue $INSTALL_MEDIA "InstallMedia" $true) 

# If the variables are not set, values from the configuration file will be used instead
$parameters = @{}

$parameters.Add("INSTALLLOCATION", (Get-VariableValue $INSTALLLOCATION "" $useHardcodedDefaults))
$parameters.Add("PIDKEY", (Get-VariableValue $PIDKEY "" $useHardcodedDefaults))

# Install OWA 2013
log "INFO:: Installing OWA 2013"
$result = (Install-OWA2013Binaries $scriptPath $mediaLocation $configFileName $parameters)
  
log "INFO: Finished $msg. `nExit code $result"

if($result -eq 0)
{
    return $result
}
else
{
    if ($result -eq 30066)
    {
        throw "ERROR: Pre-reqs check failure. Install all pre-reqs before installing OWA Server 2013. Exit code $result"
    }
    elseif ($result -eq 3010)
    {
        log "INFO: Install succeeded but requires REBOOT. If this script was executed manually, please REBOOT the server. Otherwise Agility will take care of it."
    }
    else
    {
        throw "ERROR: OWA2013 install failed. Exit code $result"
    }
}
 
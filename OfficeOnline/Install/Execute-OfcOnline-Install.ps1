Param(
    [string] $scriptPath
)

############################################################################################
# Author: Marina Krynina
#################################################################################################


########################################################################################################
# Installs OfficeOnline Binaries
########################################################################################################
function Install-OfficeOnlineBinaries([string] $scriptPath, [string] $mediaLocation, [string] $configFile)
{
    # new location of the silent config file
    $sourceConfigFile = (Join-Path $scriptPath $configFile)
    log ("INFO sourceConfigFile = " + $sourceConfigFile)

    #region Validation
    if (!(CheckFileExists( $sourceConfigFile)))
    {
        throw "ERROR: $sourceConfigFile does not exist"
    }
    #endregion

    $targetConfigFile = (Join-Path ( Join-Path (Join-Path $scriptPath $mediaLocation) "\files\setupsilent\") (Split-Path $sourceConfigFile -Leaf))
    log ("INFO targetConfigFile = " + $targetConfigFile)

    # copy config file to the media location
    ((Get-Content ( $sourceConfigFile)) -replace ("SCRIPTPATH", $scriptPath)) |% {$_.replace("`n", "`r`n")} | Out-File -filepath $targetConfigFile 
   

    Update-ConfigXML "INSTALLLOCATION" $INSTALLLOCATION $sourceConfigFile $targetConfigFile
    Update-ConfigXML "PIDKEY" $PIDKEY $sourceConfigFile $targetConfigFile

    $arguments = "/config " + $targetConfigFile
    $path =  (Join-Path $scriptPath (Join-Path $mediaLocation "Setup.exe"))

    $result = LaunchProcessAsAdministrator $path $arguments
    log "INFO: Exit code $result"

    return $result
}

#################################################################
# Main
#################################################################
Set-Location -Path $scriptPath 

# Load Common functions
. .\FilesUtility.ps1
. .\LaunchProcess.ps1
. .\LoggingV3.ps1 $true $scriptPath "Execute-OfcOnline-Install.ps1"

if ([string]::IsNullOrEmpty($VARIABLES) -eq $true)
{
    throw "ERROR: Variable containing name of the Variables script is empty"
}

log ("INFO: VARIABLES = " + $VARIABLES)
. .\$VARIABLES

try
{
    $startDate = get-date

    $msg = "Installing OfficeOnline binaries"
    log "INFO: $msg"

    # Install OfficeOnline
    log "INFO: Installing OfficeOnline"
    log ("INFO: INSTALL_MEDIA = " + $INSTALL_MEDIA)
    log ("INFO: SILENTINSTALL_XML = " + $SILENTINSTALL_XML)

    $result = (Install-OfficeOnlineBinaries $scriptPath $INSTALL_MEDIA $SILENTINSTALL_XML)
  
    log "INFO: Finished $msg. `nExit code $result"

    $endDate = get-date
    $ts = New-TimeSpan -Start $startDate -End $endDate
    log "TIME: Processing Time  - $ts"

    if($result -eq 0)
    {
        return $result
    }
    else
    {
		if ($result -eq 3010)
		{
			log "WARNING: Result code is 3010. The installation was successful. However, reboot is required.`nINFO: If running as an install script Agility Platform will restart the instance automatically.`nINFO: Otherwise you should initiate a restart before continuing."
            $result = 0
            return $result
		}
        elseif($result -eq 30030)
        {
            throw "ERROR: Failed to validate PIDKEY. The key is incorrect. Verify that you have the correct key. Exit code $result"
        }
        elseif ($result -eq 30066)
        {
            throw "ERROR: Pre-reqs check failure. Install all pre-reqs before installing OfficeOnline. Exit code $result"
        }
        else
        {
            throw "ERROR: OfficeOnline install failed. Exit code $result"
        }
    }
}
 catch [Exception]
{
    $ex = $_.Exception | format-list | Out-String
    log "ERROR: Exception occurred `nException Message: $ex"
    throw "ERROR: Exception occurred `nException Message: $ex"
}
Param(
    [string] $scriptPath
)

 ############################################################################################
# Author: Marina Krynina
# Desc:   Functions to support installation of SharePoint 2016 
#################################################################################################


########################################################################################################
# Updates farm configuration files. Farm configuration files are based on config xml provided by AutoSPInstaller.
# This update is required because AutoSPInstaller script reads DataDir from its own xml file.
########################################################################################################
function UpdateFarmConfigurationFiles([string]$scriptPath, [string]$configFile, [hashtable]$parameters)
{
    # UPDATE AUTOSPINSTALL CONFIG FILES IF THEY EXIST
    # This is required because autoSPInstaller script tries to read DataDir from its own xml file.

    [string] $configFileName = (Split-Path "$scriptPath\$configFile" -Leaf)
    $farmConfigXml = "$scriptPath\$CONFIG_XML"

    [xml]$xml = (Get-Content $farmConfigXml)

    $fileUpdated = $false
    
    $nodes = $xml.SelectNodes("//Configuration/Install/ConfigFile")
    if($nodes -ne $null)
    {
        $xml.Configuration.Install.ConfigFile = $configFileName
        $fileUpdated = $true
    }

    $nodes = $xml.SelectNodes("//Configuration/Install/DataDir")
    if($nodes -ne $null)
    {
        $xml.Configuration.Install.DataDir = $parameters.Get_Item("DATADIR")
        $fileUpdated = $true
    }

    $nodes = $xml.SelectNodes("//Configuration/Install/InstallDir")
    if($nodes -ne $null)
    {
        $xml.Configuration.Install.InstallDir = $parameters.Get_Item("INSTALLLOCATION")
        $fileUpdated = $true
    }

    if ($fileUpdated)
    {
        CreateBackupCopy $farmConfigXml

        $xml.Save($farmConfigXml)    
        log "INFO: $farmConfigXml updated, ConfigFile = $configFileName"
    }
}

########################################################################################################
# Installs SharePoint Binaries
########################################################################################################
function Install-SharePointBinaries([string] $scriptPath, [string] $mediaLocation, [string] $configFile, [hashtable] $parameters)
{
    # new location of the silent config file
    $sourceConfigFile = (Join-Path $scriptPath $configFile)
    $configFileName = Split-Path $sourceConfigFile -Leaf
    log ("INFO sourceConfigFile = " + $sourceConfigFile + ", configFileName" + $configFileName)

    #region Validation
    if (!(CheckFileExists( $sourceConfigFile)))
    {
        throw "ERROR: $sourceConfigFile does not exist"
    }

    if ($parameters -eq $null)
    {
        throw "ERROR: paramaters is null"
    }

    #endregion

    $targetConfigFile = (Join-Path (Join-Path $scriptPath $mediaLocation) $configFileName)
    $setupPath = (Join-Path (Join-Path $scriptPath $mediaLocation) "setup.exe")
    log ("INFO targetConfigFile = " + $targetConfigFile + ", setupPath = " + $setupPath)

    # copy config file to the media location
    Get-Content ( $sourceConfigFile) |% {$_.replace("`n", "`r`n")} | Out-File -filepath $targetConfigFile

    # check if logging path folder exists, if not - create
    $loggingPath = $parameters.Get_Item("LOGGINGPATH")
    if((CheckFolderExists $loggingPath) -eq $false)
    {
        New-Item $loggingPath -ItemType directory
        log "INFO: Created $loggingPath folder"
    }

    Update-ConfigXML "INSTALLLOCATION" $parameters.Get_Item("INSTALLLOCATION") $sourceConfigFile $targetConfigFile
    Update-ConfigXML "DATADIR" $parameters.Get_Item("DATADIR") $sourceConfigFile $targetConfigFile
    Update-ConfigXML "PIDKEY" $parameters.Get_Item("PIDKEY") $sourceConfigFile $targetConfigFile
    Update-XMLAttribute "//Configuration/Logging" "Path" $parameters.Get_Item("LOGGINGPATH") $targetConfigFile

    # UPDATE AUTOSPINSTALL (farm configuration) CONFIG FILES IF THEY EXIST
    UpdateFarmConfigurationFiles $scriptPath $configFileName $parameters
    
    # INSTALL SP2016
    $arguments = "/config " + $targetConfigFile
    $path =  (Join-Path $mediaLocation "Setup.exe")
    $result = LaunchProcessAsAdministrator $path $arguments

    log "INFO: Microsoft Sharepoint Installer returned : $result";
    if ( $result -ne 0 ) 
    {
        if($result -eq 30066)
        {
            throw "WARNING: A system restart from a previous installation or update is pending. Restart your computer and run setup to continue."
        }
        elseif ($result -eq 3010)
		{
			log "WARNING: Result code is 3010. The installation was successful. However, reboot is required.`nINFO: If running as an install script Agility Platform will restart the instance automatically.`nINFO: Otherwise you should initiate a restart before continuing."
            $result = 0
            return $result
		}
        else
        {
            throw "ERROR: SharePoint installer exited with code: $result `nException Message: $($_.Exception.Message)"
        }
    }
    else
    {
        return $result
    }
}

############################################################################################
# Main
############################################################################################
Set-Location -Path $scriptPath 

. .\FilesUtility.ps1
. .\VariableUtility.ps1
. .\LaunchProcess.ps1
. .\PlatformUtils.ps1
. .\LoggingV3.ps1 $true $scriptPath "Execute-SP2016-Install.ps1"

try
{
    $startDate = get-date

    if ([string]::IsNullOrEmpty($VARIABLES) -eq $true)
    {
        throw "ERROR: Variable containing name of the Variables script is empty"
    }

    log ("INFO: VARIABLES = " + $VARIABLES)
    . .\$VARIABLES

    log "INFO: Installing SharePoint 2016"
    log "INFO: Default SharePoint installer logs are located at C:\Users\<User>\AppData\Local\Temp directory. `nType cd %temp% to access the log files."

    $parameters = @{}
    $parameters.Add("INSTALLLOCATION", $INSTALLLOCATION)
    $parameters.Add("DATADIR", $DATADIR)
    $parameters.Add("PIDKEY", $PIDKEY)
    $parameters.Add("LOGGINGPATH", $LOGGINGPATH)
    log ("INFO: INSTALLLOCATION = " + $INSTALLLOCATION + "; DATADIR = " + $DATADIR + "; LOGGINGPATH = " + $LOGGINGPATH)
    log ("INFO: INSTALL_MEDIA = " + $INSTALL_MEDIA + "; SILENTINSTALL_XML = " + $SILENTINSTALL_XML)

    # INSTALL SHAREPOINT BINARIES
    $result = (Install-SharePointBinaries $scriptPath $INSTALL_MEDIA $SILENTINSTALL_XML $parameters)
    log "INFO: result = $result"

    $endDate = get-date
    $ts = New-TimeSpan -Start $startDate -End $endDate
    log "TIME: Processing Time  - $ts"
    return $result 
}
catch [Exception]
{
    $ex = $_.Exception | format-list | Out-String
    log "ERROR: Exception occurred `nException Message: $ex"
    throw "ERROR: Exception occurred `nException Message: $ex"
} 
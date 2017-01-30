Param(
    [string] $scriptPath
)

 ############################################################################################
# Author: Marina Krynina
# Desc:   Functions to support installation of SharePoint 2013 
# Updates:
#          2014-11-12
#          2014-11-13 Added WCF 5.6 to the list
#################################################################################################


########################################################################################################
# Updates farm configuration files. Farm configuration files are based on config xml provided by AutoSPInstaller.
# This update is required because AutoSPInstaller script reads DataDir from its own xml file.
########################################################################################################
function UpdateFarmConfigurationFiles([string]$scriptPath, [string]$configFileName, [hashtable]$parameters)
{
    # UPDATE AUTOSPINSTALL CONFIG FILES IF THEY EXIST
    # go through all xml files and if Configuration.ConfigFile node exists, update it with the name of this config
    # This is required because autoSPInstaller script tries to read DataDir from its own xml file.
    $files = Get-ChildItem -Path "$scriptPath\Config\*" -Include *.xml

    foreach($file in $files)
    {
        CreateBackupCopy $file
        [xml]$xml = (Get-Content $file)
    
        $nodes = $xml.SelectNodes("//Configuration/Install/ConfigFile")
        if($nodes -ne $null)
        {
            $xml.Configuration.Install.ConfigFile = $configFileName
        }

        $nodes = $xml.SelectNodes("//Configuration/Install/DataDir")
        if($nodes -ne $null)
        {
            $xml.Configuration.Install.DataDir = $parameters.Get_Item("DATADIR")
        }

        $nodes = $xml.SelectNodes("//Configuration/Install/InstallDir")
        if($nodes -ne $null)
        {
            $xml.Configuration.Install.InstallDir = $parameters.Get_Item("INSTALLLOCATION")
        }

        $xml.Save($file.FullName)    
        log "INFO: $file updated, ConfigFile = $configFileName"
    }
}

########################################################################################################
# Installs SharePoint 2013 Binaries
########################################################################################################
function Install-SharePoint2013Binaries([string] $scriptPath, [string] $mediaLocation, [string] $configFileName, [hashtable] $parameters)
{
    $targetConfigFile = "$scriptPath\$mediaLocation\$configFileName"
    $sourceConfigFile = $scriptPath + "\Install\$configFileName"

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

    CreateBackupCopy $targetConfigFile

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

    $arguments = "/config " + $targetConfigFile
    $path =  "$mediaLocation\Setup.exe"

    # UPDATE AUTOSPINSTALL (farm configuration) CONFIG FILES IF THEY EXIST
    UpdateFarmConfigurationFiles $scriptPath $configFileName $parameters
    
    # INSTALL SP2013
    $result = LaunchProcessAsAdministrator $path $arguments

    log "INFO: Microsoft Sharepoint 2013 Installer returned : $result";
    if ( $result -ne 0 ) 
    {
        if($result -eq 30066)
        {
            throw "WARNING: A system restart from a previous installation or update is pending. Restart your computer and run setup to continue."
        }
        elseif ($result -eq 3010)
        {
            log "INFO: Install succeeded but requires REBOOT. If this script was executed manually, please REBOOT the server. Otherwise Agility will take care of it."
        }
        else
        {
            throw "ERROR: SharePoint 2013 installer exited with code: $result `nException Message: $($_.Exception.Message)"
        }
    }

    return 0
}

############################################################################################
# Main
############################################################################################
# Load Common functions
. .\FilesUtility.ps1
. .\VariableUtility.ps1
. .\PlatformUtils.ps1
. .\LaunchProcess.ps1

Set-Location -Path $scriptPath 

# Folder structure in the Global Repository
# \Global Repository
#	\SharePoint2013 = $SOURCE,  folder name in the Global Repository

# Folder structure on VM
# C:\Users\InstallerAccount
#		\InstallMedia = $INSTALL_MEDIA - the content of the isntall media will be extracted here
#			\PrerequisiteInstallerFiles	- location of the prerequisite files

log "INFO: Installing SharePoint 2013"
log "INFO: Default SharePoint installer logs are located at C:\Users\<User>\AppData\Local\Temp directory. `nType cd %temp% to access the log files."

# If the Agility variables are not set, values from the configuration file will be used instead
log "INFO: Getting variables values or setting defaults if the variables are not populated."
$installMedia = (Get-VariableValue $INSTALL_MEDIA "InstallMedia" $true) 
$mediaLocation = "$installMedia"

$domain = get-domainshortname
$user = (Get-VariableValue $ADMIN "agilitydeploy" $true)
$password = get-serviceAccountPassword -username $user

$configFileName = (Get-VariableValue $CONFIG_XML "SilentConfig.xml" $true) 

# $useHardcodedDefaults is used to force default varicables. Useful for testing outside of Agility
$useHardcodedDefaults = $false
$parameters = @{}
$parameters.Add("INSTALLLOCATION", (Get-VariableValue $INSTALLLOCATION "E:\Program Files\Microsoft Office Servers\15.0\" $useHardcodedDefaults))
$parameters.Add("DATADIR", (Get-VariableValue $DATADIR "G:\Program Files\Microsoft Office Servers\15.0\Data" $useHardcodedDefaults))
$parameters.Add("PIDKEY", (Get-VariableValue $PIDKEY "" $useHardcodedDefaults)) # TODO: PIDKEY should be in key-value store?
$parameters.Add("LOGGINGPATH", (Get-VariableValue $LOGGINGPATH "L:\LogFiles\Setup" $useHardcodedDefaults))


# Create secured Credential object
$secure_pwd = convertto-securestring $password -asplaintext -force
$dcred = new-object -typename System.Management.Automation.PSCredential -argumentlist "$domain\$user", $secure_pwd 

# INSTALL SHAREPOINT BINARIES
$result = (Install-SharePoint2013Binaries $scriptPath $mediaLocation $configFileName $parameters)
return $result 
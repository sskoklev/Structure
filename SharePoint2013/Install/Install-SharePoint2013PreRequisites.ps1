Param(
    [string] $scriptPath
)

 ############################################################################################
# Author: Marina Krynina
# Desc:   Functions to support installation of SharePoint 2013 pre-requisites
# Updates:
#          2014-11-12
#          2014-11-13 Added WCF 5.6 to the list
#################################################################################################


########################################################################################################
# Installs SharePoint 2013 Pre-requisites
########################################################################################################

function Install-SPPrereqs([string] $mediaLocation, [string] $prereqsLocation, [System.Management.Automation.PSCredential] $dcred)
{
    log "INFO: Installing SharePoint Pre-reqs."
    $result = (Install-SharePoint2013PreReqs $mediaLocation $prereqsLocation $dcred)
    log "INFO: Finished Installing SharePoint Pre-reqs. `nExit code $result"
    if ($result -ne 0)
    {
        throw "ERROR: Failed to install SharePoint Pre-reqs. Exit code $result"
    }

    return $result
}

function Install-SharePoint2013PreReqs([string] $mediaLocation, [string] $prereqsLocation, [System.Management.Automation.PSCredential] $dcred)
{
    # some sources state that the argument list must be in one line
	$argumentList =  "/unattended `
                        /SQLNCli:`"$prereqsLocation\sqlncli.msi`" `
                        /IDFX:`"$prereqsLocation\Windows6.1-KB974405-x64.msu`" `
                        /Sync:`"$prereqsLocation\Synchronization.msi`" `
                        /AppFabric:`"$prereqsLocation\WindowsServerAppFabricSetup_x64.exe`" `
                        /IDFX11:`"$prereqsLocation\MicrosoftIdentityExtensions-64.msi`" `
                        /MSIPCClient:`"$prereqsLocation\setup_msipc_x64.msi`" `
                        /WCFDataServices:`"$prereqsLocation\WcfDataServices.exe`" `
                        /WCFDataServices56:`"$prereqsLocation\WcfDataServices56.exe`" `
                        /KB2671763:`"$prereqsLocation\AppFabric1.1-RTM-KB2671763-x64-ENU.exe`""


    $result = (LaunchProcessAsAdministrator "$mediaLocation\prerequisiteinstaller.exe" $argumentList)
    
    if ( Test-Path "C:\Windows\System32\sqlncli*" )
    {
		if ($result -eq 0 -or $result -eq 3010)
		{
			log "WARNING: The Sharepoint 2013 prerequisites installation was successful.`nINFO: If running as an install script Agility Platform will restart the instance automatically.`nINFO: Otherwise you should initiate a restart before continuing."
            $result = 0
            return $result
		}
		elseif ($result -eq 1001)
		{
			throw "ERROR: The instance requires a restart before the Sharepoint 2013 prerequisites can be installed.`nERROR: Please restart the instance and try the prerequisites installation again."
		}
		elseif ($result -eq 1)
		{
			throw "ERROR: There is another instance of prerequisiteinstaller.exe running.`ERROR: Please wait for the other Sharepoint 2013 prerequisiteinstaller.exe to finish and try again."
		}
		elseif ($result -eq 2)
		{
			throw "ERROR: There is an error in the command line paramaters for installing Sharepoint 2013 prerequisites.`nERROR: Please check the command line options in this script and try the prerequisites installation again."
		}
		elseif ($result -eq 999)
		{
			throw "ERROR: prerequisiteinstaller.exe is missing in $mediaLocation.`nERROR: Please check $mediaLocation and try the prerequisites installation again."
		}
    }
	else
	{
		throw "ERROR: The file 'sqlncli*.dll' was not detected.`n An unkown error has occurred preventing instalaltion of the Sharepoint 2013 prerequisites."
	}
 
}


############################################################################################
# Main
############################################################################################
# Load Common functions
. .\FilesUtility.ps1
. .\VariableUtility.ps1
. .\PlatformUtils.ps1
. .\LaunchProcess.ps1

# get current script location
Set-Location -Path $scriptPath 

# Folder structure in the Global Repository
# \Global Repository
#	\SharePoint2013 = $SOURCE,  folder name in the Global Repository

# Folder structure on VM
# C:\Users\InstallerAccount
#		\InstallMedia = $INSTALL_MEDIA - the content of the isntall media will be extracted here
#			\PrerequisiteInstallerFiles	- location of the prerequisite files

log "INFO: Installing SharePoint 2013 pre-requisites"
log "INFO: Default SharePoint installer logs are located at C:\Users\<User>\AppData\Local\Temp directory. `nType cd %temp% to access the log files."

# If the Agility variables are not set, values from the configuration file will be used instead
log "INFO: Getting variables values or setting defaults if the variables are not populated."
$installMedia = (Get-VariableValue $INSTALL_MEDIA "InstallMedia" $true) 
$mediaLocation = "$scriptPath\$installMedia"
$prereqsLocation= "$mediaLocation\PrerequisiteInstallerFiles"

$domain = get-domainshortname
$user = (Get-VariableValue $ADMIN "agilitydeploy" $true)
$password = get-serviceAccountPassword -username $user

# Create secured Credential object
$secure_pwd = convertto-securestring $password -asplaintext -force
$dcred = new-object -typename System.Management.Automation.PSCredential -argumentlist "$domain\$user", $secure_pwd 

$result = (Install-SPPrereqs $mediaLocation $prereqsLocation $dcred)

if($result -eq 3010)
{
    log "WARNING: Server reboot is required."
    $result = 0
}

return $result 
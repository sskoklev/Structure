Param(
    [string] $scriptPath,
    [string] $ver = "2016"
)

 ############################################################################################
# Author: Marina Krynina
# Desc:   Functions to support installation of SharePoint 2016 pre-requisites
#################################################################################################


########################################################################################################
# Installs SharePoint 2016 Pre-requisites
########################################################################################################

function Install-SPPrereqs([string] $mediaLocation, [string] $prereqsLocation)
{
    log "INFO: Installing SharePoint Pre-reqs."
    $result = (Install-SharePointPreReqs $mediaLocation $prereqsLocation)
    log "INFO: Finished Installing SharePoint Pre-reqs. `nExit code $result"
    if ($result -ne 0)
    {
        throw "ERROR: Failed to install SharePoint Pre-reqs. Exit code $result"
    }

    return $result
}

function Install-SharePointPreReqs([string] $mediaLocation, [string] $prereqsLocation)
{
    # some sources state that the argument list must be in one line
    $argumentList = “/unattended `
                        /SQLNCli:`"$prereqsLocation\sqlncli.msi`" `
                        /Sync:`"$prereqsLocation\Synchronization.msi`" `
                        /AppFabric:`"$prereqsLocation\WindowsServerAppFabricSetup_x64.exe`" `
                        /IDFX11:`"$prereqsLocation\MicrosoftIdentityExtensions-64.msi`" `
                        /MSIPCClient:`"$prereqsLocation\setup_msipc_x64.exe`" `
                        /KB3092423:`"$prereqsLocation\AppFabric-KB3092423-x64-ENU.exe`" `
                        /WCFDataServices56:`"$prereqsLocation\WcfDataServices56.exe`" `
	                    /ODBC:`"$prereqsLocation\msodbcsql.msi`" `
                        /DotNetFx:`"$prereqsLocation\NDP46-KB3045557-x86-x64-AllOS-ENU.exe`" `
                        /MSVCRT11:`"$prereqsLocation\vcredist_x64.exe`" `
                        /MSVCRT14:`"$prereqsLocation\vc_redist.x64.exe`""

    $result = (LaunchProcessAsAdministrator "$mediaLocation\prerequisiteinstaller.exe" $argumentList)
    
    if ( Test-Path "C:\Windows\System32\sqlncli*" )
    {
		if ($result -eq 0 -or $result -eq 3010)
		{
			log "WARNING: The Sharepoint prerequisites installation was successful.`nINFO: If running as an install script Agility Platform will restart the instance automatically.`nINFO: Otherwise you should initiate a restart before continuing."
            $result = 0
            return $result
		}
		elseif ($result -eq 1001)
		{
			throw "ERROR: The instance requires a restart before the Sharepoint Prerequisites can be installed.`nERROR: Please restart the instance and try the prerequisites installation again."
		}
		elseif ($result -eq 1)
		{
			throw "ERROR: There is another instance of Prerequisiteinstaller.exe running.`ERROR: Please wait for the other Sharepoint prerequisiteinstaller.exe to finish and try again."
		}
		elseif ($result -eq 2)
		{
			throw "ERROR: There is an error in the command line paramaters for installing Sharepoint Prerequisites.`nERROR: Please check the command line options in this script and try the prerequisites installation again."
		}
		elseif ($result -eq 999)
		{
			throw "ERROR: prerequisiteinstaller.exe is missing in $mediaLocation.`nERROR: Please check $mediaLocation and try the prerequisites installation again."
		}
    }
	else
	{
		throw "ERROR: The file 'sqlncli*.dll' was not detected.`n An unkown error has occurred preventing instalaltion of the Sharepoint Prerequisites."
	}
 
}

# ===================================================================================
# Func: Install-AppFabricCU
# Desc: Attempts to install a recently-released cumulative update for AppFabric, if found in $env:SPbits\PrerequisiteInstallerFiles
# ===================================================================================
function Install-AppFabricCU
{
    # Create a hash table with major version to product year mappings
    $spYears = @{"14" = "2010"; "15" = "2013"; "16" = "2016"}
    $spYear = $spYears.$ver

    [hashtable]$updates = @{"CU7" = "AppFabric-KB3092423-x64-ENU.exe";
                            "CU6" = "AppFabric-KB3042099-x64-ENU.exe";
                            "CU5" = "AppFabric1.1-KB2932678-x64-ENU.exe";`
                            "CU4" = "AppFabric1.1-RTM-KB2800726-x64-ENU.exe"}
    $installSucceeded = $false
    log " - Checking for AppFabric CU4 or newer..."
    $appFabricKB = (((Get-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Updates\AppFabric 1.1 for Windows Server\KB2800726" -Name "IsInstalled" -ErrorAction SilentlyContinue).IsInstalled -eq 1) -or `
                    ((Get-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Updates\AppFabric 1.1 for Windows Server\KB2932678" -Name "IsInstalled" -ErrorAction SilentlyContinue).IsInstalled -eq 1) -or
                    ((Get-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Updates\AppFabric 1.1 for Windows Server\KB3042099" -Name "IsInstalled" -ErrorAction SilentlyContinue).IsInstalled -eq 1) -or
                    ((Get-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Updates\AppFabric 1.1 for Windows Server\KB3092423" -Name "IsInstalled" -ErrorAction SilentlyContinue).IsInstalled -eq 1))
        if (!$appFabricKB) # Try to install the AppFabric update if it isn't detected
        {
            foreach ($CU in ($updates.Keys | Sort-Object -Descending))
            {
                try
                {
                    $currentUpdate = $updates.$CU
                    # Check that we haven't already succeded with one of the CUs
                    if (!$installSucceeded)
                    {
                        # Check if the current CU exists in the current path
                        log "CU4 or newer was not found."
                        log "  - Looking for update: `"$prereqsLocation\$currentUpdate`"..."
                        if (Test-Path -Path (Join-Path $prereqsLocation $currentUpdate) -ErrorAction SilentlyContinue)
                        {
                            log "  - Installing $currentUpdate..."
                            Start-Process -FilePath (Join-Path $prereqsLocation $currentUpdate) -ArgumentList "/passive /promptrestart" -Wait -NoNewWindow
                            if ($?)
                            {
                                $installSucceeded = $true
                                log " - Done."
                            }
                        }
                        else
                        {
                            log "  - AppFabric CU $currentUpdate wasn't found, looking for other update files..."
                        }
                    }
                }
                catch
                {
                    $installSucceeded = $false
                    log "  - Something went wrong with the installation of $currentUpdate."
                }
            }
        }
        else
        {
            $installSucceeded = $true
           log " - Already installed."
        }
    if (!$installSucceeded)
    {
       log " - Either no required AppFabric updates were found in $prereqsLocation, or the installation failed."
    }   
}

############################################################################################
# Main
############################################################################################
Set-Location -Path $scriptPath 

# Load Common functions
. .\FilesUtility.ps1
. .\VariableUtility.ps1
. .\LaunchProcess.ps1
. .\LoggingV3.ps1 $true $scriptPath "Execute-SP2016-PreReqs-Install.ps1"

# Folder structure on VM
# scriptPath
#		\InstallMedia = $INSTALL_MEDIA - the content of the isntall media will be extracted here
#			\PrerequisiteInstallerFiles	- location of the prerequisite files

try
{
    $startDate = get-date

    if ([string]::IsNullOrEmpty($VARIABLES) -eq $true)
    {
        throw "ERROR: Variable containing name of the Variables script is empty"
    }

    log ("INFO: VARIABLES = " + $VARIABLES)
    . .\$VARIABLES

    log "INFO: Installing SharePoint pre-requisites"
    log "INFO: Default SharePoint installer logs are located at C:\Users\<User>\AppData\Local\Temp directory. `nType cd %temp% to access the log files."

    # If the Agility variables are not set, values from the configuration file will be used instead
    log "INFO: Getting variables values or setting defaults if the variables are not populated."
    $installMedia = $INSTALL_MEDIA
    $mediaLocation = (Join-Path $scriptPath $installMedia)
    $prereqsLocation= (Join-Path $mediaLocation $PREREQS_LOCATION)
    log ("INFO: INSTALL_MEDIA = " + $INSTALL_MEDIA + "; mediaLocation = " + $mediaLocation + "; prereqsLocation = " + $prereqsLocation)

    $result = (Install-SPPrereqs $mediaLocation $prereqsLocation)
    log "INFO: result = $result"

    if($result -eq 3010)
    {
        log "WARNING: Server reboot is required."
        $result = 0
    }

     # Try to apply a recent CU for the AppFabric Caching Service if we're installing at least SP2013
    log "INFO: Installing AppFabric CU"
    Install-AppFabricCU $xmlinput
    log "INFO: Finished Installing AppFabric CU"

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
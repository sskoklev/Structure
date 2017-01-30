# MWS2R2 - Extract App Files ###############################################################
# Author: Marina Krynina
# Desc:   Extracts application files (ISO, ZIP)
############################################################################################

# Mandatory heading
# Load Common functions
. .\GlobalRepository.ps1
. .\Logging.ps1
. .\VariableUtility.ps1
. .\FilesUtility.ps1
. .\LaunchProcess.ps1

# get current script location
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$scriptName = $MyInvocation.MyCommand.Name
ConfigureLogging $scriptPath $scriptName

#########################################################################
# Main 
#########################################################################
try
{
    # Folder structure in the Global Repository
    # \Global Repository
    #	\$SOURCE,  folder name in the Global Repository

    # Folder structure on VM
    # C:\Users\InstallerAccount
    #		\$INSTALL_MEDIA - the content of the isntall media will be extracted here

    log "INFO: Getting variables values or setting defaults if the variables are not populated."
    $installMedia = (Get-VariableValue $INSTALL_MEDIA "" $false) 

    # Extracting
    $msg = "Extracting application installation files"
    log "INFO: Starting $msg"
    
    # 7za920.exe does not support ISO files, 7z.exe does.
    # 7z files are located in the Common folder and copied by default
    $extractionTool = "$scriptPath\7z.exe"

    if (([string]::IsNullOrEmpty($installMedia)) -eq $true)
    {
        $installMediaSource = "$scriptPath"
    }
    else
    {
        $installMediaSource = "$scriptPath\$installMedia"
    }
	
    Extract $extractionTool $installMediaSource

    log "INFO: Finished $msg."

    exit 0
}
catch
{
    $ex = $_.Exception | format-list | Out-String
    log "ERROR: Exception occurred `nException Message: $ex"

    exit 1
}
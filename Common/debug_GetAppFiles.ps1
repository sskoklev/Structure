# MWS2 - Get App Files ##############################################################
# Author: Marina Krynina
# Desc:   Deploys installation files onto the target server
############################################################################################

# Load Common functions
. .\GlobalRepository.ps1
. .\VariableUtility.ps1
. .\FilesUtility.ps1
. .\LaunchProcess.ps1

#########################################################################
# Main 
# - Deploys installation files onto the target server
#########################################################################
try
{
    $scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
    . .\LoggingV2.ps1 $true $scriptPath "GetAppFiles.ps1"

    log "INFO: Getting variables values or setting defaults if the variables are not populated."
    $sourceFolders = (Get-VariableValue $SOURCE "" $false) 

    foreach($srcFolder in ($sourceFolders.Replace(" ", "")).Split(","))
    {
        log "INFO: Deploying $srcFolder folder onto the target VM"
        get-appfiles $srcFolder    
    }

    log "INFO: Finished $msg."

    exit 0
}
catch
{
    $ex = $_.Exception | format-list | Out-String
    log "ERROR: Exception occurred `nException Message: $ex"

    exit 1
}
#################################################################################################
# Author: Stiven Skoklevski
# Desc:   Functions to support preparation of Windows
#################################################################################################

try
{
    $scriptPath = $env:USERPROFILE
    . .\LoggingV2.ps1 $true $scriptPath "ConfigureSQLWindows.ps1"

    # Apply windows feature
    . .\ConfigureWindowsFeature.ps1

    # Create and set MWS registry settings
    . .\ConfigureMWS2Registry.ps1
    CreateCustomNodes $MWSREGISTRYXMLFILENAME

    # Apply SCCM requirements
    . .\Install\ApplySCCMRequirements.ps1

    exit 0
}
catch
{
    $ex = $_.Exception | format-list | Out-String
    log "ERROR: Exception occurred `nException Message: $ex"

    exit 1
}      
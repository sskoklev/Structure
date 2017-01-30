Param(
    [string] $scriptPath
)

############################################################################################
# Main
# Author: Marina Krynina
############################################################################################
Set-Location -Path $scriptPath 

# Load Common functions
. .\FilesUtility.ps1
. .\PlatformUtils.ps1
. .\LaunchProcess.ps1
. .\Construct-URL.ps1

# Logging must be configured here. otherwise it gets lost in the nested calls# 
 . .\LoggingV3.ps1 $true $scriptPath "SP2016-PSConfigUI.ps1"

try
{
    log "INFO:: Starting execution of PSCONFIGUI"
    log "Current location = $scriptPath"

    . .\Config\Configure-SP2016-Functions.ps1

    $startDate = get-date

    Execute-PSConfigUI

    exit 0
}
catch 
{
    log "ERROR: $($_.Exception.Message)"
    exit $_.Exception.HResult
}
finally
{
    $endDate = get-date
    $ts = New-TimeSpan -Start $startDate -End $endDate
    log "TIME: Processing Time  - $ts"
}
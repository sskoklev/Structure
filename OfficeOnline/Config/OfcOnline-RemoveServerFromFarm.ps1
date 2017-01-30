Param(
    [string] $scriptPath
)

############################################################################################
# Main
############################################################################################
Set-Location -Path $scriptPath 
 . .\LoggingV3.ps1 $true $scriptPath "OfcOnline-RemoveServerFromFarm.ps1"

try
{
    log "INFO: Start removing the current server from the Office Online farm"

    $startDate = get-date

    Import-Module OfficeWebApps 
    Remove-OfficeWebAppsMachine

    log "INFO: removing server done"

    return 0
}
catch
{
    
    log "ERROR: $($_.Exception.Message)"
    throw "ERROR: $($_.Exception.Message)"
}
finally
{
    $endDate = get-date
    $ts = New-TimeSpan -Start $startDate -End $endDate
    log "TIME: Processing Time  - $ts"
}
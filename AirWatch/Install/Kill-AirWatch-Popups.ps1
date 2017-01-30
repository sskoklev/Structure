Param(
    [string] $scriptPath
)

. .\LoggingV3.ps1 $true $scriptPath "Wait-And-Stop-AirWatchPopup.ps1"

$parentProcessMainTitle = "AirWatch Reports"
$popupTitle = "AirWatch Reports - InstallShield Wizard"

Start-Sleep 60

While ((get-process | where {($_.mainWindowTitle).ToUpper() -eq ($parentProcessMainTitle).ToUpper()}) -ne $null)
{
    # start monitoring for popups
    log "INFO: Waiting for " + $popupTitle

    $i = 1
    $p = (get-process | where {($_.mainWindowTitle).ToUpper() -eq ($popupTitle).ToUpper()})
    While ($p -eq $null)
    {
        Start-Sleep 60
        log "."
        $p = (get-process | where {($_.mainWindowTitle).ToUpper() -eq ($popupTitle).ToUpper()})
    }

    Stop-Process -Name $p.Name

    $i += 1
    if ($i -eq 3)
    {
        log "INFO: The popup was stopped 3 times. Exiting the function"
        return 0
    }
}

log ("WARNING: The parent process hasn't started " + $parentProcessMainTitle)
return -1
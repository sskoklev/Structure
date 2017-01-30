Param(
    [string]$curLocation,
    $timeout
)

# Author: Marina Krynina

############################################################################################
# Main
############################################################################################
# Load Common functions
$scriptPath = $curLocation
Set-Location -Path $scriptPath 

. .\LoggingV3.ps1 $true $scriptPath "Set-ServicesTimeout.ps1"
. .\ServicesUtility.ps1

try
{
    # Turns off Smart screen prompt
    $state = "Off"
    log "INFO: Disable SmartScreen otherwise a prompt is raised."
    Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer -Name SmartScreenEnabled -ErrorAction Stop -Value $State -Force 

    $startDate = get-date

    log "INFO: Setting Services Start Timeout"

    Set-ServiceStartTimeout $timeout
 
    log ("INFO: Finished Setting Services Start Timeout")

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
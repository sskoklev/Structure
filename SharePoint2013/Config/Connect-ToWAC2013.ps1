Param(
    [string] $scriptPath,
    [string] $wacServer
)


############################################################################################
# Main
# Author: Marina Krynina
############################################################################################

Set-Location -Path $scriptPath 

# Load Common functions
. .\LoggingV2.ps1 $true $scriptPath "Connect-ToWAC2013.ps1"

try
{
    $msg = "Start connecting SharePoint farm to Office Web App farm"
    log "INFO: Starting $msg"

    If ((Get-PsSnapin |?{$_.Name -eq "Microsoft.SharePoint.PowerShell"})-eq $null)
    {
        log "INFO: Loading SharePoint PowerShell Snapin..."
        Add-PsSnapin Microsoft.SharePoint.PowerShell -ErrorAction Stop | Out-Null
    }

    log "INFO: binding sharepoint farm to $wacServer"
    New-SPWOPIBinding -ServerName $wacServer

    log "INFO: Finished $msg."
    return 0
}
catch
{
    throw "ERROR: $($_.Exception.Message)"
}
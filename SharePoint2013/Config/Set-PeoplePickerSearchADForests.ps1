Param(
    [string] $scriptPath,
    [string] $trustingDomain,
    [string] $trustedDomainsList
)

############################################################################################
# Main
# Author: Marina Krynina
############################################################################################

Set-Location -Path $scriptPath 

 # Logging must be configured here. otherwise it gets lost in the nested calls# 
 . .\LoggingV2.ps1 $true $scriptPath "Set-PeoplePickerSearchADForests.ps1"

log "INFO:: Setting Encryption Key for one way trust"
log "Rnning the script under identity of $env:USERDOMAIN\$env:USERNAME"
log "Current location = $scriptPath"

try
{
    # web app URL
    log "INFO: Adding SharePoint snapin"
    Add-PsSnapin Microsoft.SharePoint.PowerShell -ErrorAction Stop | Out-Null
    $urls = ""
    log "INFO: Getting Web Applications"
    $spWebApps = Get-SpWebApplication
    foreach($spWA in $spWebApps)
    {
        $urls += ($spWA.Url + ",")
    }
    log "INFO: Web Apps URLs = $urls"

    # STSADM
    Set-Alias -Name stsadm -Value $env:CommonProgramFiles"\Microsoft Shared\Web Server Extensions\15\bin\STSADM.EXE"

    # if there are more thn 1 web application in the farm, $url should be comma delimited string of web apps urls
    $urlsArray = $urls -split ","
    foreach($url in $urlsArray)
    {
        if ($url -ne "")
        {
            log "stsadm -o setproperty -pn peoplepicker-searchadforests -pv domain:$trustingDomain;$trustedDomainsList -url $url"
            stsadm -o setproperty -pn peoplepicker-searchadforests -pv "domain:$trustingDomain;$trustedDomainsList" -url $url 
        }
    }

    return 0
}
catch 
{
    log "ERROR: $($_.Exception.Message)"

    # This is done to get an error code from the scheduled task.
    Write-Output  $($_.Exception.Message) | Out-File "$scriptPath\error.txt" -Append
    throw "ERROR: $($_.Exception.Message)"
}



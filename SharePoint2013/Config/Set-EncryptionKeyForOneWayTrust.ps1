Param(
    [string] $scriptPath,
    [string] $password
)

############################################################################################
# Main
# Author: Marina Krynina
############################################################################################

Set-Location -Path $scriptPath 

 # Logging must be configured here. otherwise it gets lost in the nested calls# 
 . .\LoggingV2.ps1 $true $scriptPath "Set-EncryptionKeyForOneWayTrust.ps1"

log "INFO:: Setting Encryption Key for one way trust"
log "Rnning the script under identity of $env:USERDOMAIN\$env:USERNAME"
log "Current location = $scriptPath"

try
{
    Set-Alias -Name stsadm -Value $env:CommonProgramFiles"\Microsoft Shared\Web Server Extensions\15\bin\STSADM.EXE"
    stsadm -o setapppassword -password $password
    
    return 0
}
catch 
{
    log "ERROR: $($_.Exception.Message)"

    # This is done to get an error code from the scheduled task.
    Write-Output  $($_.Exception.Message) | Out-File "$scriptPath\error.txt" -Append
    throw "ERROR: $($_.Exception.Message)"
}



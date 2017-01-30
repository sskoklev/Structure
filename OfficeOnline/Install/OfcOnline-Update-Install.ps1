Param(
    [string] $scriptPath,
    [string] $patchLocation,
    [string] $patches
)

# Author: Marina Krynina



############################################################################################
# Main
############################################################################################
Set-Location -Path $scriptPath 

. .\LoggingV3.ps1 $true $scriptPath "OfcOnline-Update-Install.ps1"

# Load Common functions
. .\FilesUtility.ps1
. .\PlatformUtils.ps1
. .\LaunchProcess.ps1
. .\ServicesUtility.ps1

try
{
    Disable-SmartScreen            
    
    log "INFO: Getting all specified files in $patchLocation"
    $patchesArray = $patches -split ","
    if ($patchesArray.Count -ne 0)
    {
        Stop-Services "WAS,W3SVC"
        iisreset -stop -noforce 


        ForEach ($update in $patchesArray) 
        {
            log ("INFO: Update = " + $update)
            
            if (($update -eq $null) -or ($update -eq ""))
            {
                continue
            }
            
            $startDate = get-date

            # Ensure Patch is Present
            $patchfile = Get-ChildItem -Path "$patchLocation" | where{$_.Name -like $update} 
            if($patchfile -eq $null) 
            { 
              throw "ERROR: Unable to retrieve $patchLocation\$update file.  Update is specified but missing"     
            }


            log "INFO: Installing update $update" 

            $process = Join-Path $patchLocation $update
            $argument = "/passive ; exit `$LastExitCode"

            $domain = get-domainshortname

            log "INFO: Calling $process under identity $domain\$ADMIN"
            log "INFO: Arguments $argument"
            $Result = 0
            $Result = LaunchProcessWithHighestPrivAsUser $process $argument "$domain\$ADMIN" (get-serviceAccountPassword -username $ADMIN)

            log "INFO: Installation complete with return code $Result" 

            if ($Result -ne 0)
            {
                throw "ERROR: CU $update failed to install with return code $Result"
            }
        }
    }

    exit $Result
}
catch
{
    log "ERROR: $($_.Exception.Message)"
    throw "ERROR: $($_.Exception.Message)"
}
finally
{
    Stop-Services "WAS,W3SVC"
    iisreset -start

    $endDate = get-date
    $ts = New-TimeSpan -Start $startDate -End $endDate
    log "TIME: Processing Time  - $ts"
}
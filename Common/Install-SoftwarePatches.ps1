Param(
    [string] $scriptPath,
    [string] $installFile,
    [string] $arguments
)

# Author: Stiven Skoklevski

############################################################################################
# Main
############################################################################################
# Load Common functions
Set-Location -Path $scriptPath 
$scriptName = $MyInvocation.MyCommand.Name
$logName = Split-Path $installFile -Leaf

. .\LoggingV3.ps1 $true $scriptPath $logName

try
{
    $startDate = get-date

    $msg = "Start installation of SCOM Patches"
    log "INFO: Starting $msg"

    log ("INFO: $installFile")
    log ("INFO: `"$arguments`"")

    if ($installFile.EndsWith("msi"))
    {
        Start-Process -FilePath "msiexec.exe" -ArgumentList ("/i `"$installFile`" " + $arguments) -NoNewWindow -Wait
    }
    elseif ($installFile.EndsWith("msp"))
    {
        Start-Process -FilePath "msiexec.exe" -ArgumentList ("/update `"$installFile`" " + $arguments) -NoNewWindow -Wait
    }
    else
    {
        Start-Process -FilePath $installFile -ArgumentList $arguments -Wait
    }

    $endDate = get-date
    $ts = New-TimeSpan -Start $startDate -End $endDate
    log "TIME: Processing Time  - $ts"

    return 0
}
catch
{
    throw "ERROR: $($_.Exception.Message)"
}
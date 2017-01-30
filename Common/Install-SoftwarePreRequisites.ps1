Param(
    [string] $scriptPath,
    [string] $installFile,
    [string] $arguments
)

# Author: Marina Krynina

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

    $msg = "Start installation of Prerequisites"
    log "INFO: Starting $msg"

    # must be executed as Admin.
    # Turns off Smart screen prompt
    $state = "Off"
    log "INFO: Disable SmartScreen otherwise a prompt is raised."
    Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer -Name SmartScreenEnabled -ErrorAction Stop -Value $State -Force 

    log ("INFO: $installFile")
    log ("INFO: `"$arguments`"")

    if ($installFile.EndsWith("msi"))
    {
        $p = Start-Process -FilePath "msiexec.exe" -ArgumentList ("/i `"$installFile`" " + $arguments) -NoNewWindow -Wait -PassThru
    }
    elseif ($installFile.EndsWith("msu"))
    {
        $p = Start-Process -FilePath "wusa.exe" -ArgumentList (" `"$installFile`" " + $arguments) -NoNewWindow -Wait -PassThru
    } 
    else 
    {
        $p = Start-Process -FilePath $installFile -ArgumentList $arguments -NoNewWindow -Wait -PassThru
    }

    log ("INFO: Exit Code = " + $p.ExitCode)

    exit $p.ExitCode
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
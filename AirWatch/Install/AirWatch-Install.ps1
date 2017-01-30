Param(
    [string] $scriptPath,
    [string] $installFile,
    [string] $arguments,
    [string] $parameters,
    [string] $AWRSEXE,
    [string] $AWRSSVCLOCATION,
    [string] $AWRSLOCATION
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

    $msg = "Start installation of AirWatch software"
    log "INFO: Starting $msg"

    # must be executed as Admin.
    # Turns off Smart screen prompt
    $state = "Off"
    log "INFO: Disable SmartScreen otherwise a prompt is raised."
    Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer -Name SmartScreenEnabled -ErrorAction Stop -Value $State -Force 

    log ("INFO: installFile = " + $installFile)
    log ("INFO: arguments = " + $arguments)
    log ("INFO: parameters = " + $parameters)
    log ("INFO: AWRSEXE = " + $AWRSEXE)
    log ("INFO: AWRSSVCLOCATION = " + $AWRSSVCLOCATION)
    log ("INFO: AWRSLOCATION = " + $AWRSLOCATION)

    if(![String]::IsNullOrEmpty($AWRSEXE))
    {
        $parameters = $parameters + " AWRSEXE=" + "\""" + $AWRSEXE + "\""" + " AWRSSVCLOCATION=" + "\""" + $AWRSSVCLOCATION + "\""" + " AWRSLOCATION=" + "\""" + $AWRSLOCATION + "\"""
    }

    if ($installFile.EndsWith("msi"))
    {
        $p = Start-Process -FilePath "msiexec.exe" -ArgumentList ("/i `"$installFile`" " + $arguments) -NoNewWindow -Wait -PassThru
    }
    else
    {
        $arguments = $arguments + """" + $parameters + """"

        log ("INFO: ArgumentList = " + $arguments)
        
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
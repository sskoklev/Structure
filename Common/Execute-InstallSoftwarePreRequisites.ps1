Param(
    [string] $scriptPath
)

# Author: Marina Krynina

function Execute-InstallSoftwarePrereqs([xml] $xmlinput)
{
    $nodes = $xmlinput.SelectNodes("//InstallSet/Install")
    if (([string]::IsNullOrEmpty($nodes)))
    {
        log "INFO: No prerequisites to install configured in: '$inputFile'"
        return 0
    }

    $rv = 0
    foreach ($node in $nodes) 
    {
        [string]$serverList = $node.attributes['Server'].value
        [string]$filePath = $node.attributes['FilePath'].value
        [string]$arguments = $node.attributes['Arguments'].value
        [string]$installAccount = $node.attributes['InstallAccount'].value
        
        #region Attributes Validation
        if([String]::IsNullOrEmpty($serverList))
        {
            log "WARNING: serverList is empty, check the configuration file"
            continue
        }

        if([String]::IsNullOrEmpty($filePath))
        {
            log "WARNING: filePath is empty, check the configuration file"
            continue
        }

        if([String]::IsNullOrEmpty($installAccount))
        {
            log "WARNING: installAccount is empty, check the configuration file"
            continue
        }

        #endregion

        $password = get-serviceAccountPassword -username $installAccount
        $domain = get-domainshortname

        if(![String]::IsNullOrEmpty($arguments))
        {
            $arguments = $arguments.Replace("SCRIPTPATH", $scriptPath)

            $currentDate = Get-Date -Format yyyyMMdd-hhmmss
            $arguments = $arguments.Replace("CURRENTDATE", $currentDate)
        }

        $servers = $serverList.Split(",")
        $servers | Where-Object { 
        log "INFO: target server $_, current server $env:COMPUTERNAME"
        if((Get-ServerName ($_.Trim())).ToUpper() -eq ($env:COMPUTERNAME).ToUpper()) 
            {
                $installFile = $scriptPath + $filePath

                if ((CheckFileExists $installFile) -eq $false)
                {
                    throw "ERROR: $filePath is missing"
                }

                log "INFO: About to install $filePath with arguments $arguments on server $env:COMPUTERNAME"

   
                $process = "$PSHOME\powershell.exe"
                $argument = "-file $scriptPath\Install-SoftwarePreRequisites.ps1 -scriptPath $scriptPath -installFile $installFile -arguments `"$arguments`" ; exit `$LastExitCode"
                    
                log "INFO: $process $argument `"$domain\$installAccount`" "
                $Result = LaunchProcessWithHighestPrivAsUser $process $argument "$domain\$installAccount" $password

                # debug
                # . .\Install-SoftwarePreRequisites.ps1 $scriptPath $installFile $arguments

                if ($Result -eq 0)
                {
                    log "INFO: Exit code $Result"
                }
                else
                {
                    log "WARNING: Exit code $Result"
                    $rv = -1
                }

                if ($Result -eq "5")
                {
                    log "ERROR: Installation of $filePath failed with error code: (0x00000005), Access is denied."
                }

                if ($Result -eq "3010")
                {
                    # An exit code of 3010 is not an error, it simply indicates that a restart is pending
                    log "WARNING: An exit code of 3010 was returned. An exit code of 3010 is not an error, it simply indicates that a restart is pending. `n NOTE: If you are running `n - as an operational script then perform a manual reboot, `n - as an install script then consider setting the Agility script reboot option to true or perform a manual reboot."
                }
            }
        }
    }

    if ($rv -ne 0)
    {
        log "`n************************************************`n   WARNING: One or more installs returned Non-Zero Exit Code. Please review above output.`n************************************************"
    }
}

############################################################################################
# Main
############################################################################################
# Load Common functions
. .\FilesUtility.ps1
. .\VariableUtility.ps1
. .\PlatformUtils.ps1
. .\LaunchProcess.ps1

Set-Location -Path $scriptPath 
. .\LoggingV3.ps1 $true $scriptPath "Execute-InstallSoftwarePrereqs.ps1"

try
{
    $startDate = get-date

    $msg = "Start installation of Prerequisites"
    log "INFO: Starting $msg"

    $inputFile = Get-VariableValue $PREREQSCONFIG_XML "\ConfigFiles\Prerequisites.xml" $true
    $inputFile = ($scriptPath + $inputFile)

    if ((CheckFileExists($inputFile )) -eq $false)
    {
        log "INFO: $inputFile is missing"
        return 1
    }

    # Get the xml Data
    $xmlinput = [xml](Get-Content $inputFile)

    # Install
    Execute-InstallSoftwarePrereqs $xmlinput

    log "INFO: Finished $msg."
    $endDate = get-date
    $ts = New-TimeSpan -Start $startDate -End $endDate
    log "TIME: Processing Time  - $ts"

    return 0
}
catch
{
    throw "ERROR: $($_.Exception.Message)"
}
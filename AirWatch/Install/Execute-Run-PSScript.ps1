Param(
    [string] $scriptPath
)

# Author: Marina Krynina

function RunPSScripts([xml] $xmlinput)
{
    $nodes = $xmlinput.SelectNodes("//ScriptsSet/Script")
    if (([string]::IsNullOrEmpty($nodes)))
    {
        log "INFO: No script to run is configured in: '$inputFile'"
        return 0
    }

    $rv = 0
    foreach ($node in $nodes) 
    {
        [string]$serverList = $node.attributes['Server'].value
        [string]$process = (Join-Path $PSHOME ($node.attributes['FilePath'].value))
        [string]$arguments = ($node.attributes['Arguments'].value -replace("SCRIPTPATH", $scriptPath))
        [string]$installAccount = $node.attributes['InstallAccount'].value
        
        #region Attributes Validation
        if([String]::IsNullOrEmpty($serverList))
        {
            log "WARNING: serverList is empty, check the configuration file"
            continue
        }

        #endregion

        if(![String]::IsNullOrEmpty($installAccount))
        {
            $password = get-serviceAccountPassword -username $installAccount
            $domain = get-domainshortname
        }

        $servers = $serverList.Split(",")
        $servers | Where-Object { 
        log "INFO: target server $_, current server $env:COMPUTERNAME"
        if((Get-ServerName ($_.Trim())).ToUpper() -eq ($env:COMPUTERNAME).ToUpper()) 
            {
                log "INFO: About to run $filePath with arguments $arguments on server $env:COMPUTERNAME"

  
                if(![String]::IsNullOrEmpty($installAccount))
                {
                    log "INFO: Launching $process with arguments $($arguments) under identity `"$domain\$installAccount`" "
                    $Result = LaunchProcessWithHighestPrivAsUser $process $arguments "$domain\$installAccount" $password
                }
                else
                {
                    log "INFO: Launching $process with arguments $($arguments) as Local Admin "
                    $Result = LaunchProcessAsAdministrator $process $arguments

                }


                if ($Result -eq 0)
                {
                    log "INFO: Exit code $Result"
                }
                else
                {
                    log "WARNING: Exit code $Result"
                    $rv = -1
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
. .\LoggingV3.ps1 $true $scriptPath "Execute-Run-PSSCripts.ps1"

try
{
    $startDate = get-date

    $msg = "Start executing configured PS scripts"
    log "INFO: Starting $msg"

    $inputFile = Get-VariableValue $SCRIPTS_XML "\ConfigFiles\AW-Scripts.xml" $true
    $inputFile = (Join-Path $scriptPath $inputFile)

    if ((CheckFileExists($inputFile )) -eq $false)
    {
        log "INFO: $inputFile is missing"
        return 1
    }

    # Get the xml Data
    $xmlinput = [xml](Get-Content $inputFile)

    # Install
    RunPSScripts $xmlinput
    log "INFO: Finished $msg."

    return 0
}
catch
{
    throw "ERROR: $($_.Exception.Message)"
}
finally
{
    $endDate = get-date
    $ts = New-TimeSpan -Start $startDate -End $endDate
    log "TIME: Processing Time  - $ts"
}
 Param(
    [string] $scriptPath,
    [string] $setupPath,
    [string] $targetConfigFile,
    [string] $VARIABLES
)

# Author: Marina Krynina
# credits to AutoSpInstaller

Function Get-SharePointInstall
{
    # New(er), faster way courtesy of SPRambler (https://www.codeplex.com/site/users/view/SpRambler)
    if ((Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*) | Where-Object {$_.DisplayName -like "Microsoft SharePoint Server*"})
    {
        return $true
    }
    else {return $false}
}

Function InstallSharePoint
{
    $spYear = "2016"
    $spInstalled = Get-SharePointInstall
    If ($spInstalled)
    {
        log "INFO: SharePoint $spYear binaries appear to be already installed - skipping installation."
    }
    Else
    {
        # Install SharePoint Binaries
        If (Test-Path $setupPath)
        {
            log "INFO: Installing SharePoint $spYear binaries..." 
            $startTime = Get-Date
            Start-Process $setupPath -ArgumentList "/config `"$targetConfigFile`"" -Wait -windowstyle Hidden
                        
            $delta,$null = (New-TimeSpan -Start $startTime -End (Get-Date)).ToString() -split "\."
            log "INFO: SharePoint $spYear setup completed in $delta."
            If (-not $?)
            {
                Throw "ERROR: Error $LASTEXITCODE occurred running $setupPath"
            }

            # Parsing most recent SharePoint Server Setup log for errors or restart requirements, since $LASTEXITCODE doesn't seem to work...
            $setupLog = Get-ChildItem -Path (Get-Item $env:TEMP).FullName | ? {$_.Name -like "*SharePoint * Setup*"} | Sort-Object -Descending -Property "LastWriteTime" | Select-Object -first 1
            If ($setupLog -eq $null)
            {
                Throw "ERROR: Could not find SharePoint Server Setup log file!"
            }

            # Get error(s) from log
            $setupLastError = $setupLog | Select-String -SimpleMatch -Pattern "Error:" | Select-Object -Last 1
            $setupSuccess = $setupLog | Select-String -SimpleMatch -Pattern "Successfully installed package: oserver"

            If ($setupLastError -and !$setupSuccess)
            {
                log $setupLastError.Line
                Invoke-Item -Path "$((Get-Item $env:TEMP).FullName)\$setupLog"
                Throw "ERROR: Review the log file and try to correct any error conditions."
            }

            # Look for restart requirement in log
            $setupRestartNotNeeded = $setupLog | select-string -SimpleMatch -Pattern "System reboot is not pending."
            If (!($setupRestartNotNeeded))
            {
                Throw "ERROR: SharePoint setup requires a restart. Run the script again after restarting to continue."
            }

            log "INFO: Waiting for SharePoint Products and Technologies Wizard to launch..." 
            While ((Get-Process |?{$_.ProcessName -like "psconfigui*"}) -eq $null)
            {
                log "." 
                Start-Sleep 1
            }
            log "INFO: Done."
            log "INFO: Exiting Products and Technologies Wizard - using PowerShell instead!"
            Stop-Process -Name psconfigui
        }
        Else
        {
            Throw "ERROR: Install path $setupPath not found!!"
        }
    }
}

############################################################################################
# Main
############################################################################################
Set-Location -Path $scriptPath 

. .\FilesUtility.ps1
. .\LoggingV3.ps1 $true $scriptPath "SP2016-Install.ps1"

try
{
    $startDate = get-date

    if ([string]::IsNullOrEmpty($VARIABLES) -eq $true)
    {
        throw "ERROR: Variable containing name of the Variables script is empty"
    }

    log ("INFO: VARIABLES = " + $VARIABLES)
    . .\$VARIABLES

    InstallSharePoint

    $endDate = get-date
    $ts = New-TimeSpan -Start $startDate -End $endDate
    log "TIME: Processing Time  - $ts"
    return $result 
}
catch [Exception]
{
    $ex = $_.Exception | format-list | Out-String
    log "ERROR: Exception occurred `nException Message: $ex"
    
    # This is done to get an error code from the scheduled task.
    Write-Output  $($_.Exception.Message) | Out-File "$scriptPath\error.txt" -Append

    throw "ERROR: Exception occurred `nException Message: $ex"
} 
Param(
    [string] $scriptPath,
    [string] $installOption
)

# Author: Marina Krynina

# ===================================================================================
# Desc: Updates the config file(s) with derived values 
# ===================================================================================
function UpdateInputFile ([string] $inputFile, [string] $scriptPath)
{
    if ((CheckFileExists($inputFile )) -eq $false)
    {
        throw "ERROR: $inputFile is specified but missing"
    }

    CreateBackupCopy $inputFile
    [xml]$xmlinput = (Get-Content $inputFile)

    [string]$dnsZone = $xmlinput.InstallSet.DNSZone
    [string]$installer = $xmlinput.InstallSet.InstallAccount
    [string]$certLocation = ($xmlinput.InstallSet.CertificateLocation -replace("SCRIPTPATH", $scriptPath))
    [string]$certPassword = $xmlinput.InstallSet.CertificatePassword

    $xmlinput.InstallSet.CertificateLocation = $certLocation

    $nodes = $xmlinput.SelectNodes("//InstallSet/Install") | where-object {($_.attributes['InstallType'].value).ToUpper() -eq $installOption.ToUpper()} 

    if (([string]::IsNullOrEmpty($nodes)))
    {
        throw "WARNING: No nodes of type $installOption configured in: $($inputFile)"
    }

    foreach ($node in $nodes) 
    {
        $servers = ($node.attributes['Server'].value).Split(",")
        $servers | Where-Object { 
            log "INFO: target server $_, current server $env:COMPUTERNAME"
            if((Get-ServerName ($_.Trim())).ToUpper() -eq ($env:COMPUTERNAME).ToUpper())
            {
                [string]$configFileName = $node.attributes['ConfigFileName'].value
        
                if(![String]::IsNullOrEmpty($configFileName))
                {
                    $secondaryInputFile = (Join-Path (Join-Path $scriptPath "\ConfigFiles\")  $configFileName)
                    UpdateSecondaryInputFile $secondaryInputFile $scriptPath $dnsZone $installer $certLocation $certPassword
                }
            }
            } 
     }

    $xmlinput.Save($inputFile)
}

# ===================================================================================
# Desc: Updates the secondary config file that is created by AirWatch 
# ===================================================================================
function UpdateSecondaryInputFile ([string] $secondaryInputFile, [string] $scriptPath, [string]$dnsZone, [string]$installer, [string] $certLocation, [string]$certPassword)
{
    $customerId = Get-CustomerId
    $currentDate = Get-Date -Format yyyyMMddhhmmss

    [xml]$xmlSecInput = (Get-Content $secondaryInputFile)

   if ((CheckFileExists($secondaryInputFile )) -eq $false)
    {
        throw "ERROR: $secondaryInputFile is specified but missing"
    }

    CreateBackupCopy $secondaryInputFile

    $customerId = Get-CustomerId
    $domain = get-domainshortname

    $installerPwd = (get-serviceAccountPassword -username $installer)

    [xml]$xmlSecInput = (Get-Content $secondaryInputFile) -replace ("SCRIPTPATH", $scriptPath) `
                                                            -replace("CURRENTDATE", $currentDate) `
                                                            -replace("CUSTOMERID", $customerId) `
                                                            -replace("DOMAIN", $domain) `
                                                            -replace("CUSTOMERID", $customerId) `
                                                            -replace("DNSZONE", $dnsZone) `
                                                            -replace("SERVICEACCOUNT", $installer) `
                                                            -replace("SVCACCTPASSWORD", $installerPwd) `
                                                            -replace("CERTIFICATELOCATION", $certLocation) `
                                                            -replace("CERTIFICATEPASSWORD", $certPassword)
    $xmlSecInput.Save($secondaryInputFile)
}
# ===================================================================================
function Execute-InstallSoftware([xml] $xmlinput)
{
    try
    {
        $customerId = Get-CustomerId
        $currentDate = Get-Date -Format yyyyMMddhhmmss

        [string]$installAccount = $xmlinput.InstallSet.InstallAccount
        $password = get-serviceAccountPassword -username $installAccount
        $domain = get-domainshortname

        $nodes = $xmlinput.SelectNodes("//InstallSet/Install") | where-object {($_.attributes['InstallType'].value).ToUpper() -eq $installOption.ToUpper()} 
        foreach ($node in $nodes) 
        {
            [string]$serverList = $node.attributes['Server'].value
            [string]$filePath = $node.attributes['FilePath'].value
            [string]$configFileName = $node.attributes['ConfigFileName'].value
            [string]$arguments = $node.attributes['Arguments'].value
            [string]$AWRSEXE = $node.attributes['AWRSEXE'].value
            [string]$AWRSSVCLOCATION = $node.attributes['AWRSSVCLOCATION'].value
            [string]$AWRSLOCATION = $node.attributes['AWRSLOCATION'].value
            [string]$instance = $node.attributes['DBInstance'].value

            if (!([String]::IsNullOrEmpty($instance)))
            {
                $rsServiceName = "ReportServer$" + $instance
            }
            else
            {
                $rsServiceName = ""
            }

            #region Attributes Validation
            log "INFO: serverList = $serverList"
            log "INFO: filePath = $filePath"
            log "INFO: configFileName = $configFileName"
            log "INFO: arguments = $arguments"
            log "INFO: AWRSEXE = $AWRSEXE"
            log "INFO: AWRSSVCLOCATION = $AWRSSVCLOCATION"
            log "INFO: AWRSLOCATION = $AWRSLOCATION"
            log "INFO: instance = $instance"

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
            else
            {
                $installFile = (Join-Path $scriptPath $filePath)
                if ((CheckFileExists $installFile) -eq $false)
                {
                    log "WARNING: $installFile is missing"
                    continue
                }
            }

            if([String]::IsNullOrEmpty($installAccount))
            {
                log "WARNING: installAccount is empty, check the configuration file"
                continue
            }
            #endregion

            $parameters = ""
            if(![String]::IsNullOrEmpty($configFileName))
            {
                [string]$parameters = (($node.attributes['Parameters'].value) -replace("CONFIGFILENAME", $configFileName))
            }
            else
            {
                [string]$parameters = $node.attributes['Parameters'].value
            }

            $parameters = ((($parameters -replace ("SCRIPTPATH", $scriptPath)) -replace( "CURRENTDATE", $currentDate)) -replace("CUSTOMERID", $customerId))

            $servers = $serverList.Split(",")
            $servers | Where-Object { 
                log "INFO: target server $_, current server $env:COMPUTERNAME"
                if((Get-ServerName ($_.Trim())).ToUpper() -eq ($env:COMPUTERNAME).ToUpper()) 
                    {
                        if ($installOption.ToUpper() -eq "REPORTS")
                        {
                            $parameters = (($parameters -replace ("DBSERVER", (Get-ServerName ($_.Trim())))) -replace( "INSTANCENAME", $instance)) 
                            $AWRSEXE = ($AWRSEXE -replace( "INSTANCENAME", $instance))
                            $AWRSSVCLOCATION = ($AWRSSVCLOCATION -replace( "INSTANCENAME", $instance))
                            $AWRSLOCATION = ($AWRSLOCATION -replace( "INSTANCENAME", $instance))

                            # check if we are on the server that runs ReportServer$INSTANCE service
                            # if the service is not found, exception will be thrown by Get-Service
                            $ssrs = Get-Service -Name $rsServiceName -ErrorAction Stop
                            
                            $rsStatus = $ssrs.Status
                            if ($rsStatus -ne "Running")
                            {
                                # if the service cannot be strated, an exception will be thrown
                                # if the service cannot be started, we don't want to proceed with the install
                                Start-Service $rsServiceName
                            }

                            # the install account must be a local admin
                            if (!(IfLocalAdmin "$installAccount"))
                            {
                                log "------------------------------------------------------------------------------------------------------------------------------"
                                log "INFO: Currently $installAccount is not a Local Administrator. Adding to the group as it is a requirement."
                                log "------------------------------------------------------------------------------------------------------------------------------"
                                AddUserToLocalAdministrators $env:COMPUTERNAME "$domain\$installAccount"
                            }                        }

                        $process = "$PSHOME\powershell.exe"
                        $argument = "-file $scriptPath\Install\AirWatch-Install.ps1 -scriptPath $scriptPath -installFile $installFile -arguments `"$arguments`""
                        $argument = $argument + " -parameters `"$parameters`""
                        $argument = $argument + " -AWRSEXE `"$AWRSEXE`""
                        $argument = $argument + " -AWRSSVCLOCATION `"$AWRSSVCLOCATION`""
                        $argument = $argument + " -AWRSLOCATION `"$AWRSLOCATION`""
                        $argument = $argument + " ; exit `$LastExitCode"
                    
                        log "INFO: $process $argument `"$domain\$installAccount`" "

                        $Result = 0
                        if($DEBUG -ne $true)
                        {
                            $Result = LaunchProcessWithHighestPrivAsUser $process $argument "$domain\$installAccount" $password
                        }
                        else
                        {
                            . .\Install\AirWatch-Install.ps1 $scriptPath $installFile $arguments $parameters $AWRSEXE $AWRSSVCLOCATION $AWRSLOCATION
                        }

                        log "INFO: Exit Code $Result"

                        if ($Result -ne 0)
                        {
                            throw "ERROR: $filePath Exit Code = $Result"
                        }
                    }
                }
        }
    }
    catch
    {
        throw "ERROR: $($_.Exception.Message)"
    }
    finally
    {
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
. .\UsersUtility.ps1
. .\ServicesUtility.ps1
. .\Get-SQLInstance.ps1

Set-Location -Path $scriptPath 
. .\LoggingV3.ps1 $true $scriptPath "Execute-AirWatch-Install.ps1"

try
{
    $startDate = get-date

    $msg = "Start installation of Execute-AirWatch-Install"
    log "INFO: Starting $msg"

    $inputFile = (Join-Path $scriptPath $INSTALLSET_XML) 

    # Update the config files with the tenant dependent values that can be derived
    UpdateInputFile $inputFile $scriptPath

    # Get the xml Data
    $xmlinput = [xml](Get-Content $inputFile)

    # Install
    Execute-InstallSoftware $xmlinput

    return 0
}
catch
{
    throw "ERROR: $($_.Exception.Message)"
}
finally
{
    log "INFO: Finished $msg."
    $endDate = get-date
    $ts = New-TimeSpan -Start $startDate -End $endDate
    log "TIME: Processing Time  - $ts"
}
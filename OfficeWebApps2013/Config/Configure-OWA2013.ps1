Param(
    [string] $scriptPath,
    [string] $inputFile
)

#################################################################################################
# Author: Marina Krynina
# Desc:   Functions to import SSL certificates. This function is obsolete
#################################################################################################
function Import-Certificate([string] $inputFile)
{
    [xml]$xmlinput = (Get-Content $inputFile)
    $CertificateFileLocation = $xmlinput.Configuration.CertificateFileLocation
    $CertificatePrivateKey = $xmlinput.Configuration.CertificatePrivateKey
    $CertificateName = $xmlinput.Configuration.CertificateName
    
    $secPwd = ConvertTo-SecureString -String $CertificatePrivateKey -Force –AsPlainText

    log "INFO: importing into MY store"
    $cert = ImportPfxCertificate $CertificateFileLocation $secPwd "cert:\LocalMachine\My"
    $cert.FriendlyName = $CertificateName

    log "INFO: importing into Root store"
    $cert = ImportPfxCertificate $CertificateFileLocation $secPwd "cert:\LocalMachine\Root"
    $cert.FriendlyName = $CertificateName
}

#################################################################################################
# Author: Marina Krynina
# Desc:   Configure office Web Apps Server 2013 
#################################################################################################
function ConfigureOWA2013farm([string] $inputFile)
{
    [xml]$xmlinput = (Get-Content $inputFile)

    ##Settings for OWA Farm
    $useSSL = $xmlinput.Configuration.UseSSL
    $PrimaryServer = $xmlinput.Configuration.PrimaryServer
    $CacheLocation = $xmlinput.Configuration.CacheLocation
    $CacheSizeInGB = $xmlinput.Configuration.CacheSizeInGB
    $CertificateName = $xmlinput.Configuration.CertificateName
    $InternalURL = $xmlinput.Configuration.InternalURL
    $ExternalURL = $xmlinput.Configuration.ExternalURL
    $LogLocation = $xmlinput.Configuration.LogLocation
    $LogRetentionInDays = $xmlinput.Configuration.LogRetentionInDays
    $MaxMemoryCacheSizeInMB = $xmlinput.Configuration.MaxMemoryCacheSizeInMB
    $RenderingLocalCacheLocation = $xmlinput.Configuration.RenderingLocalCacheLocation

    $currentServer = ([string]$env:COMPUTERNAME).ToUpper()
    $domain = get-domainshortname
    $domainFull = get-domainname

    Import-Module -Name OfficeWebApps
    $joinToFarm = $false

    log "INFO: Current server = $currentServer; OWA Primary Server = $PrimaryServer"
    try
    {
        log "INFO: checking if the server is part of the Office Web Apps Server farm"
        Get-OfficeWebAppsMachine
    }
    catch [System.IO.FileNotFoundException]
    {
        $notJoinedMsg = "It does not appear that this machine is part of an Office Web Apps Server farm."
        

        if ((($_.ErrorDetails).Message).Contains($notJoinedMsg))
        {
            log "INFO: $notJoinedMsg"
            $joinToFarm = $true
        }
    }

    if ($joinToFarm -eq $true)
    {
        if ($PrimaryServer -eq $currentServer)
        {

            log "INFO: creating a new farm"

            if ($useSSL -eq $true)
            {
                # Using HTTPS with WAC (recommended):
                # Provision the WAC farm 
                if ([string]::IsNullOrEmpty($ExternalURL) -eq $true)
                {
                    log "New-OfficeWebAppsFarm -CacheLocation $CacheLocation -CacheSizeInGB $CacheSizeInGB -CertificateName `"$CertificateName`" -InternalURL $InternalURL -LogLocation $LogLocation -LogRetentionInDays $LogRetentionInDays -MaxMemoryCacheSizeInMB $MaxMemoryCacheSizeInMB -RenderingLocalCacheLocation $RenderingLocalCacheLocation -EditingEnabled:true -Force"
                    New-OfficeWebAppsFarm -CacheLocation $CacheLocation -CacheSizeInGB $CacheSizeInGB -CertificateName $CertificateName -InternalURL $InternalURL -LogLocation $LogLocation -LogRetentionInDays $LogRetentionInDays -MaxMemoryCacheSizeInMB $MaxMemoryCacheSizeInMB -RenderingLocalCacheLocation $RenderingLocalCacheLocation -EditingEnabled:$true -Force
                }
                else 
                {
                    log "New-OfficeWebAppsFarm -CacheLocation $CacheLocation -CacheSizeInGB $CacheSizeInGB -CertificateName `"$CertificateName`" -InternalURL $InternalURL -ExternalUrl $ExternalURL -LogLocation $LogLocation -LogRetentionInDays $LogRetentionInDays -MaxMemoryCacheSizeInMB $MaxMemoryCacheSizeInMB -RenderingLocalCacheLocation $RenderingLocalCacheLocation -EditingEnabled:true -Force"
                    New-OfficeWebAppsFarm -CacheLocation $CacheLocation -CacheSizeInGB $CacheSizeInGB -CertificateName $CertificateName -InternalURL $InternalURL -ExternalUrl $ExternalURL -LogLocation $LogLocation -LogRetentionInDays $LogRetentionInDays -MaxMemoryCacheSizeInMB $MaxMemoryCacheSizeInMB -RenderingLocalCacheLocation $RenderingLocalCacheLocation -EditingEnabled:$true -Force
                }

                log "INFO: New Office Web App Server 2013 has been provisioned. primary server = $PrimaryServer"
            }
            else
            {
                # MK: NOT IMPLEMENTED, NOT TESTED To use HTTP with WAC (not recommended)
                # New-OfficeWebAppsFarm -Verbose -InternalURL "$internalUrl" -ExternalUrl "$externalUrl" -AllowHttp -ClipartEnabled –TranslationEnabled
            }
        }
        else
        {
            log "INFO: Joining server $PrimaryServer.$domainFull to the existing farm"
            New-OfficeWebAppsMachine -MachineToJoin "$PrimaryServer.$domainFull"
        }
    }
    else
    {
        log "INFO: The server is part of the Office Web Apps Server farm. Skipping."
    }

    return 0
}

#################################################################################################
# Author: Marina Krynina
# Desc:   
#################################################################################################

Set-Location -Path $scriptPath 

. .\LoggingV2.ps1 $true $scriptPath "Configure-OWA2013.ps1"
. .\FilesUtility.ps1
. .\SSLManagementUtility.ps1
. .\PlatformUtils.ps1
. .\VariableUtility.ps1

    try
    {
        [xml]$xmlinput = (Get-Content $inputFile)
        $useSSL = $xmlinput.Configuration.UseSSL

        ConfigureOWA2013farm $inputFile

        # Check if config was success
        #(Invoke-WebRequest https://OfficeApps.demo3.local/m/met/participant.svc/jsonAnonymous/BroadcastPing).Headers["X-OfficeVersion"]

        return 0
    }
    catch
    {
        log "ERROR: $($_.Exception.Message)"

        # This is done to get an error code from the scheduled task.
        Write-Output  $($_.Exception.Message) | Out-File "$scriptPath\error.txt" -Append
        throw "ERROR: $($_.Exception.Message)"
    }
Param(
    [string] $scriptPath,
    [string] $inputFile
)

#################################################################################################
# Author: Marina Krynina
# Desc:   Configure ConfigureOfficeOnline 
#################################################################################################
function ConfigureOfficeOnline([string] $inputFile)
{
    [xml]$xmlinput = (Get-Content $inputFile)

    ##Settings for OWA Farm
    $useSSL = $xmlinput.Configuration.UseSSL
    $editingEnabled = [System.Convert]::ToBoolean($xmlinput.Configuration.EditingEnabled)
    $sslOffloaded = [System.Convert]::ToBoolean($xmlinput.Configuration.SSLOffloaded)
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

    Import-Module -Name OfficeWebApps
    # Import-Module "D:\Program Files\Microsoft Office Web Apps\AdminModule\OfficeWebApps\OfficeWebApps.psd1"

    $joinToFarm = $false

    log "INFO: Current server = $currentServer; OfficeOnline Primary Server = $PrimaryServer"
    try
    {
        log "INFO: checking if the server is part of the Office Online Server farm"
        Get-OfficeWebAppsMachine
    }
    catch [System.IO.FileNotFoundException]
    {
        $notJoinedMsg = "It does not appear that this machine is part of an Office Online Server farm"  

        if ((($_.ErrorDetails).Message.toUpper()).Contains(($notJoinedMsg).toUpper()))
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
                $allowHttp = $false
            }
            else
            {
                $allowHttp = $true
            }
            
            # Provision the WAC farm 
            log "New-OfficeWebAppsFarm -InternalURL ""$InternalURL"" -ExternalUrl ""$ExternalURL"" -CertificateName ""$CertificateName"" -EditingEnabled:$editingEnabled -SSLOffloaded:$sslOffloaded -AllowHttp:$allowHttp -CacheLocation $CacheLocation -CacheSizeInGB $CacheSizeInGB -LogLocation $LogLocation -LogRetentionInDays $LogRetentionInDays -MaxMemoryCacheSizeInMB $MaxMemoryCacheSizeInMB -RenderingLocalCacheLocation $RenderingLocalCacheLocation -Force"
            New-OfficeWebAppsFarm -InternalURL $InternalURL `
                                    -ExternalUrl $ExternalURL `
                                    -CertificateName "$CertificateName" `
                                    -EditingEnabled:$editingEnabled `
                                    -SSLOffloaded:$sslOffloaded `
                                    -AllowHttp:$allowHttp `
                                    -CacheLocation $CacheLocation `
                                    -CacheSizeInGB $CacheSizeInGB `
                                    -LogLocation $LogLocation `
                                    -LogRetentionInDays $LogRetentionInDays `
                                    -MaxMemoryCacheSizeInMB $MaxMemoryCacheSizeInMB `
                                    -RenderingLocalCacheLocation $RenderingLocalCacheLocation -Force -ErrorAction Stop

            log "INFO: New Office Online Server 2016 has been provisioned. primary server = $PrimaryServer"
        }
        else
        {
            $ps = [System.Net.Dns]::GetHostByName($PrimaryServer) | select HostName
            log ("INFO: Joining server $currentServer to the existing farm " + $ps.HostName.ToUpper())
            New-OfficeWebAppsMachine -MachineToJoin $ps.HostName.ToUpper()
        }

        # TO DO - for SharePOint
        # log "INFO: Specifying S2S certificate"
        # Set-OfficeWebAppsFarm -S2SCertificateName $CertificateName -Confirm:$false -Force
        # log "INFO: Restart the Office Online Server"
    }
    else
    {
        log "INFO: The server is part of the Office Online Server farm. Skipping configuration."
    }
}

#################################################################################################
# Author: Marina Krynina
# Desc:   
#################################################################################################
Set-Location -Path $scriptPath 
. .\LoggingV3.ps1 $true $scriptPath "OfcOnline-Config.ps1"

. .\FilesUtility.ps1
. .\SSLManagementUtility.ps1
. .\VariableUtility.ps1

 try
 {
    $startDate = get-date

    ConfigureOfficeOnline $inputFile

    exit 0
 }
 catch [Exception]
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
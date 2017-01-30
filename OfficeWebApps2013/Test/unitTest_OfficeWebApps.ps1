Function WriteLine
{
    log ""
    log "------------------------------------------------------------------------------------------------------------"
}

Function GetFromNode([System.Xml.XmlElement]$node, [string] $item)
{
    $value = $node.GetAttribute($item)
    If ($value -eq "")
    {
        $child = $node.SelectSingleNode($item);
        If ($child -ne $null)
        {
            Return $child.InnerText;
        }
    }
    Return $value;
}

########################################################################################################
#$scriptPath = "c:\users\mkrynina"
$scriptPath = $env:USERPROFILE
Set-Location -Path $scriptPath 
. .\LoggingV2.ps1 $true $scriptPath "unitTest_OfficeWebApps.ps1"

try
{
    . .\PlatformUtils.ps1
    
    $installFile = "$scriptPath\InstallMedia\files\setupsilent\OWA_SilentConfig.xml"
    $configFile = "$scriptPath\Config\MWS2_OWAFarm.xml"
    $cerificatesFile = "$scriptPath\Config\OfficeWebAppsCertificates.xml"

    $domain = get-domainname
    $domainFull = get-domainshortname

    WriteLine
    log "***** Domain"
    log "$domain"
    log "$domainFull"

    log "***** "
    WriteLine
    log "***** Computer name"
    log "$env:COMPUTERNAME"
    
    log "***** FQDN Computer name"
    log ([System.Net.Dns]::GetHostByName(($env:computerName))).HostName

    WriteLine
    log "***** Volumes"
    $volumes = Get-WmiObject -Class Win32_LogicalDisk | Where { $_.DriveType -eq 3 } | Format-Table | out-string
    log $volumes

    WriteLine
    log "***** WAC Install xml $installFile"
    if (Test-Path  ($installFile))
    {
        log "Exists: installFile"
    }
    else
    {
        log "ERROR: installFile does not exist"
        exit -1
    }

    [xml]$xmlinput = (Get-Content $installFile)
    $installLocation =  $xmlinput.Configuration.INSTALLLOCATION.Value
    log "Install Location = $installLocation"
    if (Test-Path  ($installLocation))
    {
        log "Exists installLocation"
    }
    else
    {
        log "ERROR: installLocation does not exist"
        exit -1
    }

    WriteLine
    log "***** WAC Config xml $configFile"
    if (Test-Path  ($configFile))
    {
        log "Exists configFile"
    }
    else
    {
        log "ERROR: configFile does not exist"
        exit -1
    }

    [xml]$xmlinput = (Get-Content $configFile)

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

    log "PrimaryServer = $PrimaryServer"
    log "CacheLocation = $CacheLocation"
    log "CacheSizeInGB = $CacheSizeInGB"
    log "CertificateName = $CertificateName"
    log "InternalURL = $InternalURL"
    log "ExternalURL = $ExternalURL"
    log "LogLocation = $LogLocation"
    log "LogRetentionInDays = $LogRetentionInDays"
    log "MaxMemoryCacheSizeInMB = $MaxMemoryCacheSizeInMB"
    log "RenderingLocalCacheLocation = $RenderingLocalCacheLocation"

    if (Test-Path  ($CacheLocation))
    {
        log "Exists CacheLocation"
    }
    else
    {
        log "ERROR: CacheLocation does not exist"
        exit -1
    }

    if (Test-Path  ($LogLocation))
    {
        log "Exists LogLocation"
    }
    else
    {
        log "ERROR: LogLocation does not exist"
        exit -1
    }

    if (Test-Path  ($RenderingLocalCacheLocation))
    {
        log "Exists RenderingLocalCacheLocation"
    }
    else
    {
        log "ERROR: RenderingLocalCacheLocation does not exist"
        exit -1
    }

    WriteLine
    log "***** WAC Server "
    Import-Module -Name OfficeWebApps
    $wacServer = Get-OfficeWebAppsMachine | Format-Table | out-string
    log $wacServer

    WriteLine
    log "***** WAC Farm "
    Import-Module -Name OfficeWebApps
    $wacFarm = Get-OfficeWebAppsFarm | Format-List | out-string
    log $wacFarm

    WriteLine
    log "***** Imported Certificates "
    $certs = Get-ChildItem -Recurse cert:\ -DNSName "*$domain*" | out-string
    log $certs

    exit 0
}
catch
{
    log "ERROR: $($_.Exception.Message)"
    exit -999
}

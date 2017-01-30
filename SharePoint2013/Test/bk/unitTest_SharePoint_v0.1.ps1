Function WriteLine
{
    log ""
    log "------------------------------------------------------------------------------------------------------------"
}

function NewLine()
{
    log "`n"
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

Function Get-RegistryKeyPropertiesAndValues
{
  <#
   .Synopsis
    This function accepts a registry path and returns all reg key properties and values
   .Description
    This function returns registry key properies and values.
   .Example
    Get-RegistryKeyPropertiesAndValues -path 'HKCU:\Volatile Environment'
    Returns all of the registry property values under the \volatile environment key
   .Parameter path
    The path to the registry key
   .Notes
    NAME:  Get-RegistryKeyPropertiesAndValues
    AUTHOR: ed wilson, msft
    LASTEDIT: 05/09/2012 15:18:41
    KEYWORDS: Operating System, Registry, Scripting Techniques, Getting Started
    HSG: 5-11-12
   .Link
     Http://www.ScriptingGuys.com/blog
 #Requires -Version 2.0
 #>
 Param(
  [Parameter(Mandatory=$true)]
  [string]$path)
 Get-Item $path |
    Select-Object -ExpandProperty property |
    ForEach-Object {
        New-Object psobject -Property @{"property"=$_;
        "Value" = (Get-ItemProperty -Path $path -Name $_).$_}}
} #end function Get-RegistryKeyPropertiesAndValues

function domainInfo()
{
    WriteLine
    log "TEST: ***** Domain"
    log "TEST: Short $domain"
    log "TEST: FQDN  $domainFull"
}

function serverInfo()
{
    WriteLine
    log "TEST: ***** Computer name"
    $server = $env:COMPUTERNAME
    log "TEST: Short name $server"
    $serverFQDN = ([System.Net.Dns]::GetHostByName(($env:computerName))).HostName
    log "TEST: FQDN       $serverFQDN"
    $serverIP = (Get-NetIPAddress | Where { ($_.AddressFamily -eq "IPv4") -and ($_.IPAddress -ne "127.0.0.1")})
    log ("TEST: IP         " + $serverIP.IPAddress)

    $cpuInfo = Get-WmiObject -ComputerName $server –Class win32_processor
    $cores = $cpuInfo.NumberOfCores
    $logicalProcs = $cpuInfo.NumberOfLogicalProcessors
    log "TEST: No of Cores: $cores"
    log "TEST: No of Logical Processors: $logicalProcs"

    $object = Get-WmiObject -ComputerName $server –Class win32_computersystem
    $memoryInGB = $('{0:N2}' –f ($object.TotalPhysicalMemory/1024/1024/1024))
    log "TEST: RAM        $memoryInGB GB"
}

function volumesInfo()
{
    WriteLine
    log "TEST: ***** Volumes"
    # $volumes = Get-WmiObject -Class Win32_LogicalDisk | Where { $_.DriveType -eq 3 } | Format-Table | out-string
    #log "TEST: $volumes"

    $drives = Get-WmiObject -ComputerName $server –Class win32_logicaldisk | Where {$_.DriveType –eq 3}
    foreach($drive in $drives)
    {
        $deviceId = $drive.DeviceId
        $volumeName = $drive.VolumeName
        $totalSize = $('{0:N2}' –f ($drive.Size/1024/1024/1024))
        $freeSpace = $('{0:N2}' –f ($drive.FreeSpace/1024/1024/1024))
        $percentageFull = $('{0:N2}' –f ($freeSpace / $totalSize * 100))

        log "TEST: $deviceId"
        log "TEST: $volumeName"
        log "TEST: Total Size: $totalSize GB"
        log "TEST: Free Space: $freeSpace GB"
        log "TEST: Percentage Full: $percentageFull %"
        NewLine
    }
}

function installLocation()
{
    WriteLine
    log "TEST: ***** $product Install xml $installFile"
    if (Test-Path  ($installFile))
    {
        log "TEST: installFile $installFile exists"
    }
    else
    {
        log "TEST: ERROR: installFile $installFile does not exist"
    }

    [xml]$xmlinput = (Get-Content $installFile)
    $installLocation =  $xmlinput.Configuration.INSTALLLOCATION.Value
    log "TEST: Install Location = $installLocation"
    if (Test-Path  ($installLocation))
    {
        log "TEST: installLocation $installLocation exists"
    }
    else
    {
        log "TEST: ERROR: installLocation $installLocation does not exist. The product has been installed in different location."
    }
}

function certificatesInfo()
{
    WriteLine
    log "TEST: ***** Imported Certificates "
    $certs = Get-ChildItem -Recurse cert:\ -DNSName "*$domain*" | out-string
    log "TEST: $certs"
}

function productInfo()
{
    WriteLine
    log "TEST: ***** $product version and build info"
    
    $products = @{
    "35466B1A-B17B-4DFB-A703-F74E2A1F5F5E" = "Project Server 2013"; 
    "BC7BAF08-4D97-462C-8411-341052402E71" = "Project Server 2013 Preview"; 
    "C5D855EE-F32B-4A1C-97A8-F0A28CE02F9C" = "SharePoint Server 2013";
    "CBF97833-C73A-4BAF-9ED3-D47B3CFF51BE" = "SharePoint Server 2013 Preview";
    "B7D84C2B-0754-49E4-B7BE-7EE321DCE0A9" = "SharePoint Server 2013 Enterprise";
    "298A586A-E3C1-42F0-AFE0-4BCFDC2E7CD0" = "SharePoint Server 2013 Enterprise Preview";
    "D6B57A0D-AE69-4A3E-B031-1F993EE52EDC" = "Microsoft Office Online";
    "9FF54EBC-8C12-47D7-854F-3865D4BE8118" = "SharePoint Foundation 2013"
    }

    $registryPath = "HKLM:software\Microsoft\Shared Tools\Web Server Extensions\$((Get-SPFarm).BuildVersion.Major).0\WSS\InstalledProducts"
    Get-RegistryKeyPropertiesAndValues -path $registryPath | 
    ForEach-Object { log "TEST: Installed product: $($products.Get_Item($_.value)) (SKU ID: $($_.value))" }   
    
    log "TEST: Installed version: $((Get-SPFarm).BuildVersion)"
}

function serviceAccountsInfo()
{
    WriteLine
    log "TEST: ***** Service Accounts"
    # farm account
    $farmAcct = (Get-SPFarm).DefaultServiceAccount.Name 
    log "TEST: Farm Account:    $farmAcct"

    # managed accounts
    $managedAccts = Get-SPManagedAccount| Select Username | out-string
    log "TEST: Managed Accounts: $managedAccts"

    # super user and reader accounts
     Get-SPWebApplication | 
     Foreach-object {log “TEST: Web Application: $($_.url) `nSuper user: $($_.properties[“portalsuperuseraccount”]) `nSuper reader: $($_.properties[“portalsuperreaderaccount”])"; NewLine}

}

function iisBindingsInfo()
{
    WriteLine
    log "TEST: ***** IIS Binding "

    Import-Module WebAdministration

   # Get-ChildItem -Path IIS:\SslBindings

    $webBinding = Get-WebBinding | Out-String
    log "TEST: Web Binding $webBinding"

    $Websites = Get-ChildItem IIS:\Sites
    log "TEST: Items in IIS:\Sites"
    foreach ($site in $Websites) 
    {
        log ("TEST: Name = " + $site.Name + ", State = " + $site.State)

        $Bindings = $site.bindings
        foreach($binding in $site.bindings.Collection)
        {
            if ((($binding.Protocol -eq "http") -or ($binding.Protocol -eq "https")) -and (([string]$binding.BindingInformation).Contains("443") -or ([string]$binding.BindingInformation).Contains("80")) )
            {
                # binding information =  <address>:<port>:<host>
                log ("TEST: Protocol = " + $binding.Protocol)
                log ("TEST: BindingInformation in [<address>:<port>:<host>] format = " + $binding.BindingInformation)
            }
        }

        NewLine
    }

    <#
        The certificates in the Server Certificates section of IIS Manager (inetmgr.exe) are certificates located in MY certificate store of the local machine, and their Enhanced Key Usage is Server Authentication.
    #>

    log "TEST: Items in IIS:\SslBindings\0.0.0.0!443"
    $bbs = Get-Item IIS:\SslBindings\0.0.0.0!443
    foreach($b in $bbs)
    {
        #log $b
        log ("TEST: Port       = " + $b.Port)
        log ("TEST: Cert Store = " + $b.Store)
        log ("TEST: Thumbprint = " + $b.Thumbprint)

        $certStore = "cert:\LocalMachine\" + $b.Store
        #Get-ChildItem -Path ($certStore + "\" +$b.Thumbprint) | Format-List -Property *
        $cert = Get-ChildItem ($certStore + "\" +$b.Thumbprint) | Select FriendlyName
        log ("TEST: FriendlyName = " + $cert.FriendlyName)
        
        $b | select -ExpandProperty Sites | select Value | foreach-object {log "TEST: Cert used in Site = $($_.Value)"}
    }
}

function farmTopology()
{ 
    WriteLine
    log "TEST: ***** Servers "

    $servers = Get-SPServer | Select DisplayName, Role

    log ("TEST: " + ($servers | Format-Table -AutoSize |out-string))
   
}

function getServiceInfo([string] $servicename)
{
    $svc = Get-WmiObject win32_service | Where-Object {$_.name -eq $servicename}
    log ("TEST: Service = $servicename, Status = " + $svc.State)
}

function spDefaultServicesCheck()
{
   getServiceInfo "SPuserCodeV4"
   getServiceInfo "SPTimerV4"
   getServiceInfo "SpTraceV4"
}

function spServiceAppsInfo()
{
    WriteLine
    log "TEST: ***** Service Apps "

    $serviceApps = Get-SPServiceApplication
    log ("TEST: " + ($serviceApps | Format-Table -AutoSize | out-string))

    $serviceAppsAppPools = Get-SPServiceApplication | Select DisplayName,{$_.ApplicationPool.Name}  
    log ("TEST: " + ($serviceAppsAppPools | Format-Table -AutoSize | out-string))
    
Get-SPServiceInstance -Server $env:COMPUTERNAME | Where{$_.Hidden –eq $False} | Select TypeName, Server, IsProvisioned, Service, Id, Status, Farm


}

########################################################################################################
$scriptPath = "c:\users\mkrynina"
#$scriptPath = $env:USERPROFILE
Set-Location -Path $scriptPath 
. .\LoggingV2.ps1 $true $scriptPath "unitTest_SharePoint.ps1"

try
{
    . .\PlatformUtils.ps1

    Add-PsSnapin Microsoft.SharePoint.PowerShell -ErrorAction Stop | Out-Null
    
    $installFile = "$scriptPath\InstallMedia\SilentConfig.xml"
    $configFile = "$scriptPath\Config\MWS2_SPFarm.xml"
    $cerificatesFile = "$scriptPath\Config\SharePointCertificates.xml"

    $domain = get-domainshortname
    $domainFull = get-domainname

    $product = "SharePoint"

    #################################################################################################
    # domainInfo
    # serverInfo
    # volumesInfo
    # installLocation
    # certificatesInfo
    # productInfo
    # serviceAccountsInfo
    # iisBindingsInfo
    # farmTopology
    # spDefaultServicesCheck
    spServiceAppsInfo

    #################################################################################################


    <#
    #################################################################################################
        WriteLine
    log "TEST: ***** $product Config xml $configFile"
    if (Test-Path  ($configFile))
    {
        log "TEST: configFile $configFile exists"
    }
    else
    {
        log "TEST: ERROR: configFile $configFile does not exist"
        exit -1
    }

    #################################################################################################

    #To get a list of all SharePoint service applications that exist in the farm, use this cmdlet:
    Get-SPServiceApplication | Select DisplayName,{$_.ApplicationPool.Name}                               
    
    #To get a list of all SharePoint Web Apps, enter the following:
    Get-SPWebApplication | Select DisplayName,Url, {$_.AlternateUrls.Count} 
    Get-SPWebApplication -IncludeCentralAdministration
    #>

    exit 0
}
catch
{
    log "TEST: ERROR: $($_.Exception.Message)"
    exit -999
}

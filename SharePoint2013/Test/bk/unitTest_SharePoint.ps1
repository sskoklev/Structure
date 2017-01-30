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

    # HTML Output
    $object = New-Object -TypeName PSObject
    $object | Add-Member -Name 'Domain' -MemberType Noteproperty -Value $domain
    $object | Add-Member -Name 'Domain FQDN' -MemberType Noteproperty -Value $domainFull

    $strObjects = $object | ConvertTo-Html -As LIST -Fragment -PreContent "<h2>Domain Info</h2>" | Out-String
    Write-Output "$strObjects"
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

 
    # HTML Output
    $object = New-Object -TypeName PSObject
    $object | Add-Member -Name 'Server' -MemberType Noteproperty -Value $server
    $object | Add-Member -Name 'Server FQDN' -MemberType Noteproperty -Value $serverFQDN
    $object | Add-Member -Name 'IP' -MemberType Noteproperty -Value $serverIP.IPAddress
    $object | Add-Member -Name 'Cores' -MemberType Noteproperty -Value $cores
    $object | Add-Member -Name 'Logical proesses' -MemberType Noteproperty -Value $logicalProcs
    $object | Add-Member -Name 'RAM (GB)' -MemberType Noteproperty -Value $memoryInGB

    $strObjects = $object | ConvertTo-Html -As LIST -Fragment -PreContent "<h2>Server Info</h2>" | Out-String
    Write-Output "$strObjects"
}

function volumesInfo()
{
    WriteLine
    log "TEST: ***** Volumes"
    # $volumes = Get-WmiObject -Class Win32_LogicalDisk | Where { $_.DriveType -eq 3 } | Format-Table | out-string
    #log "TEST: $volumes"

    $drives = Get-WmiObject -ComputerName $env:COMPUTERNAME –Class win32_logicaldisk | Where {$_.DriveType –eq 3}
    # HTML output
    $objects = @()
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

        $object = New-Object PSObject
        $object | Add-Member -MemberType NoteProperty -Name "Device Id" -Value $deviceId
        $object | Add-Member -MemberType NoteProperty -Name "Volume Name" -Value $volumeName
        $object | Add-Member -MemberType NoteProperty -Name "Total Size" -Value $totalSize
        $object | Add-Member -MemberType NoteProperty -Name "Free Space" -Value $freeSpace
        $object | Add-Member -MemberType NoteProperty -Name "Percentage Full" -Value $percentageFull
        $objects += $object        
    }

    $strObjects = $objects | ConvertTo-Html -As TABLE -Fragment -PreContent "<h2>Volumes Info</h2>" | Out-String
    Write-Output "$strObjects"
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
        $ifExist = "PASSED"
    }
    else
    {
        log "TEST: ERROR: installLocation $installLocation does not exist. The product has been installed in different location."
        $ifExist = "FAILED"
    }

   # HTML Output
    $object = New-Object -TypeName PSObject
    $object | Add-Member -Name 'Folder Exist' -MemberType Noteproperty -Value $ifExist
    $object | Add-Member -Name 'Install Location' -MemberType Noteproperty -Value $installLocation

    $strObjects = $object | ConvertTo-Html -As LIST -Fragment -PreContent "<h2>Install Location</h2>" | Out-String
    Write-Output "$strObjects"
}

function certificatesInfo()
{
    WriteLine
    log "TEST: ***** Imported Certificates "
    
    $certs = Get-ChildItem -Recurse cert:\ -DNSName "*$domain*"
    log ("TEST: " + $certs | out-string)
    
    # HTML Output
    $objects = @()
    foreach($cert in $certs)
    {
        $object = New-Object -TypeName PSObject
        $object | Add-Member -Name 'FriendlyName' -MemberType Noteproperty -Value $cert.FriendlyName
        $object | Add-Member -Name 'Thumbprint' -MemberType Noteproperty -Value $cert.Thumbprint
        $object | Add-Member -Name 'Subject' -MemberType Noteproperty -Value $cert.Subject
        $object | Add-Member -Name 'PSParentPath' -MemberType Noteproperty -Value ([string]($cert.PSParentPath)).Replace("Microsoft.PowerShell.Security\Certificate::", "")
        $objects += $object 
    }
    
    $strObjects = $objects | ConvertTo-Html -As TABLE -Fragment -PreContent "<h2>Certificates Info</h2>" | Out-String
    Write-Output "$strObjects"
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
    
    # HTML Output
    $prods = Get-RegistryKeyPropertiesAndValues -path $registryPath
    $objects = @()

    foreach($prod in $prods)
    {
        $object = New-Object -TypeName PSObject
        $object | Add-Member -Name 'Product' -MemberType Noteproperty -Value $products.Get_Item($prod.value)
        $object | Add-Member -Name 'SKU ID' -MemberType Noteproperty -Value $prod.value
        $objects += $object        
    }
        
    $version = $((Get-SPFarm).BuildVersion)

    $strObjects = $objects | ConvertTo-Html -As LIST -Fragment -PreContent "<h2>Installed products</h2><h3>Build Version $version</h3>" | Out-String
    Write-Output "$strObjects"
}

function serviceAccountsInfoORIG()
{
    WriteLine
    log "TEST: ***** Service Accounts"
    # farm account
    $farmAcct = (Get-SPFarm).DefaultServiceAccount.Name | out-string
    log "TEST: Farm Account:    $farmAcct"

    # managed accounts
    $managedAccts = Get-SPManagedAccount | Select Username
    log ("TEST: Managed Accounts: " + $managedAccts | out-string)

    # super user and reader accounts
     Get-SPWebApplication | 
     Foreach-object {log “TEST: Web Application: $($_.url) `nSuper user: $($_.properties[“portalsuperuseraccount”]) `nSuper reader: $($_.properties[“portalsuperreaderaccount”])"; NewLine}

}

function serviceAccountsInfo()
{
    # farm account
    $farmAcct = (Get-SPFarm).DefaultServiceAccount.Name | out-string

    $props = @{'Farm Account'= $farmAcct }
    $object = New-Object -TypeName PSObject -Property $props
    $farmAccountStr = $object | ConvertTo-Html -As LIST -Fragment -PreContent "<h2>Serivce and Managed Accounts</h2><h3>Farm Account</h3>" | Out-String

    # managed accounts
    $managedAccts = Get-SPManagedAccount

    $objects = @()
    # super user and reader accounts
    Get-SPWebApplication | 
    Foreach-object {$object = New-Object -TypeName PSObject; 
                    $object | Add-Member -Name 'Web App' -MemberType Noteproperty -Value $($_.url);
                    $object | Add-Member -Name 'Super user' -MemberType Noteproperty -Value $($_.properties[“portalsuperuseraccount”]);
                    $object | Add-Member -Name 'Super reader' -MemberType Noteproperty -Value $($_.properties[“portalsuperreaderaccount”]);
                    $objects += $object}

    $superUsers = $objects | ConvertTo-Html -As TABLE -Fragment -PreContent "<h3>Super users</h3>" | Out-String

    # HTML Output
    $objects = @()

    foreach($ma in $managedAccts)
    {
        $object = New-Object -TypeName PSObject
        $object | Add-Member -Name 'Managed Account' -MemberType Noteproperty -Value $ma.UserName
        $object | Add-Member -Name 'Password Expiration' -MemberType Noteproperty -Value $ma.PasswordExpiration
        $objects += $object
    }

    $strObjects = $objects | ConvertTo-Html -As TABLE -Fragment -PreContent "<h3>Managed accounts</h3>" | Out-String
    Write-Output "$farmAccountStr $strObjects $superUsers"
}
function iisBindingsInfoORIG()
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

function iisBindingsInfo()
{
    Import-Module Webadministration

    $webBinding = Get-WebBinding | Select protocol, bindingInformation, sslFlags, certificateHash, certificateStoreName, ItemXPath
    $webBindingStr = $webBinding | ConvertTo-Html -As TABLE -Fragment -PreContent "<h2>IIS Info</h2><h3>Web Bindings</h3>" | Out-String

    $Websites = Get-ChildItem IIS:\Sites
    $objects = @()

    foreach ($site in $Websites) 
    {
        $object = New-Object -TypeName PSObject
        $object | Add-Member -Name 'Site name' -MemberType Noteproperty -Value $site.Name
        $object | Add-Member -Name 'State' -MemberType Noteproperty -Value $site.State
        $objects += $object  
    }

    $iisSitesStr = $objects | ConvertTo-Html -As TABLE -Fragment -PreContent "<h3>Sites from IIS:\Sites</h3>" | Out-String

    #The certificates in the Server Certificates section of IIS Manager (inetmgr.exe) are certificates located in MY certificate store of the local machine, and their Enhanced Key Usage is Server Authentication.
    

    $objects = @()
    $sslBindings = Get-Item IIS:\SslBindings\0.0.0.0!443
    foreach($sslBind in $sslBindings)
    {
        $certStore = "cert:\LocalMachine\" + $sslBind.Store
        $cert = Get-ChildItem ($certStore + "\" +$sslBind.Thumbprint) | Select FriendlyName
        

        $object = New-Object -TypeName PSObject
        $object | Add-Member -Name 'Site Port' -MemberType Noteproperty -Value $sslBind.Port
        $object | Add-Member -Name 'Cert Store' -MemberType Noteproperty -Value $sslBind.Store
        $object | Add-Member -Name 'Thumbprint' -MemberType Noteproperty -Value $sslBind.Thumbprint
        $object | Add-Member -Name 'Friendly Name' -MemberType Noteproperty -Value $cert.FriendlyName
        
        $usedInSites = ""
        $sslBind | select -ExpandProperty Sites | select Value | foreach-object {$usedInSites = $usedInSites + "|| " + $($_.Value)}
        
        $object | Add-Member -Name 'Used In' -MemberType Noteproperty -Value $usedInSites

        $objects += $object  
    }

    $sslBindingsStr = $objects | ConvertTo-Html -As TABLE -Fragment -PreContent "<h3>SSL bindings from IIS:\SslBindings\0.0.0.0!443</h3>" | Out-String

    Write-Output "$webBindingStr $iisSitesStr $sslBindingsStr"
}
function farmTopology()
{ 
    WriteLine
    log "TEST: ***** Servers "

    $servers = Get-SPServer | Select DisplayName, Role

    log ("TEST: " + ($servers | Format-Table -AutoSize |out-string))

    # HTML Output
    $strObjects = $servers | ConvertTo-Html -As TABLE -Fragment -PreContent "<h2>Servers in the Farm</h2>" | Out-String

    Write-Output "$strObjects"   
}

function getServiceInfo([string] $servicename)
{
    $svc = Get-WmiObject win32_service | Where-Object {$_.name -eq $servicename}
    log ("TEST: Service = $servicename, Status = " + $svc.State)
    Write-Output $svc.State
}

function spDefaultServicesCheck()
{
    $defaultServices = @("SPuserCodeV4", "SPTimerV4", "SpTraceV4")

    $objects = @()
    foreach($defSvc in $defaultServices)
    {
        $object = New-Object -TypeName PSObject
        $object | Add-Member -Name 'Name' -MemberType Noteproperty -Value $defSvc
        $object | Add-Member -Name 'State' -MemberType Noteproperty -Value (getServiceInfo $defSvc)
        $objects += $object
    }

    $strObjects = $objects | ConvertTo-Html -As TABLE -Fragment -PreContent "<h2>Default Services</h2>" | Out-String
    Write-Output "$strObjects"
}

function spServiceAppsInfo()
{
    WriteLine
    log "TEST: ***** Service Apps "

    $serviceApps = Get-SPServiceApplication | Select DisplayName,ApplicationVersion,TypeName,{$_.ApplicationPool.Name},Shared,Service,NeedsUpgradeIncludeChildren,Name,Id,Status,Parent,Version,Farm #,Properties,ServiceInstances
    log ("TEST: " + ($serviceApps | Format-Table -AutoSize | out-string))
    
    $serviceAppsStr = $serviceApps | ConvertTo-Html -As TABLE -Fragment -PreContent "<h2>Service APplications</h2>" | Out-String

    $serviceInstances = Get-SPServiceInstance -Server $env:COMPUTERNAME | Select DisplayName,TypeName,Status,SearchServiceInstanceId,PrimaryHostController,Server,Service,Instance,NeedsUpgradeIncludeChildren,Id,Parent,Version,Farm #Properties
    $serviceInstancesStr = $serviceInstances | ConvertTo-Html -As TABLE -Fragment -PreContent "<h2>Services on Server</h2>" | Out-String

    Write-Output "$serviceAppsStr $serviceInstancesStr" 

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
 
    $frag1 = domainInfo  
    $frag2 = serverInfo
    $frag3 = volumesInfo
    $frag4 = installLocation
    $frag5 = certificatesInfo
    $frag6 = productInfo
    $frag7 = serviceAccountsInfo
    $frag8 = iisBindingsInfo
    $frag9 = farmTopology
    $frag10 = spDefaultServicesCheck
    $frag11 = spServiceAppsInfo

    #################################################################################################
$head = @'

<style>

body { background-color:#dddddd;

       font-family:Tahoma;

       font-size:10pt; }

td, th { border:0.5px solid grey;

         border-collapse:collapse; }

th { color:white;

     background-color:black; }

table, tr, td, th { padding: 2px; margin: 0px }

table { margin-left:50px; }

</style>

'@

 
  
ConvertTo-HTML -head $head -PostContent "$frag1 $frag2 $frag3 $frag4 $frag5 $frag6 $frag7 $frag8 $frag9 $frag10 $frag11" -PreContent "<h1>$product Unit Testing for $env:COMPUTERNAME</h1>" | Out-file "c:\users\mkrynina\test\test.html"
Invoke-Item "c:\users\mkrynina\test\test.html"

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

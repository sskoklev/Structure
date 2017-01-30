############################################################################################
# Author: Marina Krynina
# Desc: Set of common unit test functions 
############################################################################################

############################################################################################
# Author: Marina Krynina
# Desc: Sample
############################################################################################
function get-ObjectToCheckSample
{
    [CmdletBinding()]
    [OutputType([PSObject[]])]

    $objects = @()

    # Get your object here
    # $myObject = $env:USERANAME

    $object = New-Object -TypeName PSObject
    $object | Add-Member -Name 'Name' -MemberType Noteproperty -Value "SampeObject"  # $myObject.Name
    $object | Add-Member -Name 'State' -MemberType Noteproperty -Value "ImplementMe" # $myObject.State
    $objects += $object

    Write-Output $objects
}

############################################################################################
# Author: Marina Krynina
# Desc: Creates HTML fragment
############################################################################################
Function CreateHtmlFragment 
{
    [CmdletBinding()]
    [OutputType([string])]
    Param (      
        [Parameter(Mandatory=$true, ValueFromPipeline=$false, Position=0)]
        [string] $outputAs,
   
        [Parameter(Mandatory=$true, ValueFromPipeline=$false, Position=1)]
        [string] $preContent,
   
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=2)]
        [PSObject[]]$InputObject

    )

    begin { $psObj = @() }
    process { $psObj += $InputObject }
    end
    {
        if ($psObj -ne $null -and $psObj.Length -ne 0)
        {
       
            if($outputAs.ToUpper() -eq "LIST")
            {
                $psObjAsString = $psObj | ConvertTo-Html -As LIST -Fragment -PreContent $preContent | Out-String
            }

            if($outputAs.ToUpper() -eq "TABLE")
            {
                $psObjAsString = $psObj | ConvertTo-Html -As TABLE -Fragment -PreContent $preContent | Out-String
            }

            Write-Output $psObjAsString
         }
         else
         {
            Write-Output ""
         }
    }
}

############################################################################################
function get-DomainInfo()
{
    [CmdletBinding()]
    [OutputType([PSObject[]])]
    $objects = @()

    $domain = $env:USERDOMAIN
    $domainFull = $env:USERDNSDOMAIN

    $object = New-Object -TypeName PSObject
    $object | Add-Member -Name 'Domain' -MemberType Noteproperty -Value $domain
    $object | Add-Member -Name 'Domain FQDN' -MemberType Noteproperty -Value $domainFull
    $objects += $object

    Write-Output $objects
}

Function get-ServerInfo 
{
    [CmdletBinding()]
    [OutputType([PSObject[]])]
    $objects = @()
    
    # start 
    $server = $env:COMPUTERNAME
    $serverFQDN = ([System.Net.Dns]::GetHostByName(($env:computerName))).HostName
    $serverIP = (Get-NetIPAddress | Where { ($_.AddressFamily -eq "IPv4") -and ($_.IPAddress -ne "127.0.0.1")})

    $cpuInfo = Get-WmiObject -ComputerName $server –Class win32_processor

    $object = Get-WmiObject -ComputerName $server –Class win32_computersystem
    $memoryInGB = $('{0:N2}' –f ($object.TotalPhysicalMemory/1024/1024/1024))
 
    $object = New-Object -TypeName PSObject
    $object | Add-Member -Name 'Server' -MemberType Noteproperty -Value $server
    $object | Add-Member -Name 'Server FQDN' -MemberType Noteproperty -Value $serverFQDN
    $object | Add-Member -Name 'IP' -MemberType Noteproperty -Value $serverIP.IPAddress
    $object | Add-Member -Name 'Cores' -MemberType Noteproperty -Value $cpuInfo.NumberOfCores
    $object | Add-Member -Name 'Logical Processors' -MemberType Noteproperty -Value $cpuInfo.NumberOfLogicalProcessors
    $object | Add-Member -Name 'RAM (GB)' -MemberType Noteproperty -Value $memoryInGB
    # end 
    
    $objects += $object

    Write-Output $objects
}

function get-VolumesInfo()
{
    [CmdletBinding()]
    [OutputType([PSObject[]])]
    $objects = @()

    $drives = Get-WmiObject -ComputerName $env:COMPUTERNAME –Class win32_logicaldisk | Where {$_.DriveType –eq 3}
    foreach($drive in $drives)
    {
        $deviceId = $drive.DeviceId
        $volumeName = $drive.VolumeName
        $totalSize = $('{0:N2}' –f ($drive.Size/1024/1024/1024))
        $freeSpace = $('{0:N2}' –f ($drive.FreeSpace/1024/1024/1024))
        $percentageFull = $('{0:N2}' –f ($freeSpace / $totalSize * 100))

        $object = New-Object PSObject
        $object | Add-Member -MemberType NoteProperty -Name "Device Id" -Value $deviceId
        $object | Add-Member -MemberType NoteProperty -Name "Volume Name" -Value $volumeName
        $object | Add-Member -MemberType NoteProperty -Name "Total Size" -Value $totalSize
        $object | Add-Member -MemberType NoteProperty -Name "Free Space" -Value $freeSpace
        $object | Add-Member -MemberType NoteProperty -Name "Percentage Full" -Value $percentageFull
        $objects += $object        
    }

    Write-Output $objects 
}

function get-CertificatesInfo()
{
    [CmdletBinding()]
    [OutputType([PSObject[]])]
    $objects = @()

    $certs = Get-ChildItem -Recurse cert:\ -DNSName "*$domain*"
    foreach($cert in $certs)
    {
        $object = New-Object -TypeName PSObject
        $object | Add-Member -Name 'FriendlyName' -MemberType Noteproperty -Value $cert.FriendlyName
        $object | Add-Member -Name 'Thumbprint' -MemberType Noteproperty -Value $cert.Thumbprint
        $object | Add-Member -Name 'Subject' -MemberType Noteproperty -Value $cert.Subject
        $object | Add-Member -Name 'PSParentPath' -MemberType Noteproperty -Value ([string]($cert.PSParentPath)).Replace("Microsoft.PowerShell.Security\Certificate::", "")
        $objects += $object 
    }

    Write-Output $objects
}

function get-Services ($services)
{
    [CmdletBinding()]
    [OutputType([PSObject[]])]

    $objects = @()

    if ($services -ne $null -and $services.Length -gt 0)
    {
        foreach($s in $services)
        {
            $svc = ([string]$s).Trim().ToUpper()
            $service = Get-WmiObject win32_service | Where-Object {(([string]$_.name).ToUpper() -eq $svc) -or (([string]$_.displayname).ToUpper() -eq $svc)}

            $object = New-Object -TypeName PSObject
            $object | Add-Member -Name 'Given Name' -MemberType Noteproperty -Value $svc

            if ($service -eq $null)
            {
                $object | Add-Member -Name 'Service Display Name' -MemberType Noteproperty -Value ""
                $object | Add-Member -Name 'Service Name' -MemberType Noteproperty -Value ""
                $object | Add-Member -Name 'State' -MemberType Noteproperty -Value "Does Not Exist"
            }
            else
            {
                $object | Add-Member -Name 'Service Display Name' -MemberType Noteproperty -Value $service.displayname
                $object | Add-Member -Name 'Service Name' -MemberType Noteproperty -Value $service.name
                $object | Add-Member -Name 'State' -MemberType Noteproperty -Value $service.State
            }

            $objects += $object
        }
    }

    Write-Output $objects
}

function get-WebBindings
{
    [CmdletBinding()]
    [OutputType([PSObject[]])]

    $objects = @()

    Import-Module Webadministration
    $webBinding = Get-WebBinding | Select protocol, bindingInformation, sslFlags, certificateHash, certificateStoreName, 
                                            @{Name="Site";Expression={ ($_.itemXPath.substring($_.itemXPath.IndexOf("@name"))).Split("'")[1]  }},
                                            @{Name="ID";Expression={ ($_.itemXPath.substring($_.itemXPath.IndexOf("@id"))).Split("'")[1]  }}

    $objects += $webBinding

    Write-Output $objects
}

function get-IISSites
{
    [CmdletBinding()]
    [OutputType([PSObject[]])]

    $objects = @()

    $Websites = Get-ChildItem IIS:\Sites
    foreach ($site in $Websites) 
    {
        $object = New-Object -TypeName PSObject
        $object | Add-Member -Name 'Site name' -MemberType Noteproperty -Value $site.Name
        $object | Add-Member -Name 'State' -MemberType Noteproperty -Value $site.State
        $objects += $object  
    }

    Write-Output $objects
}

function get-SSLBindings()
{
    [CmdletBinding()]
    [OutputType([PSObject[]])]

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

    Write-Output $objects
}

function get-CommonHeader($dtStart, $dtEnd)
{
    [CmdletBinding()]
    [OutputType([PSObject[]])]
    $objects = @()

    $object = New-Object -TypeName PSObject
    $object | Add-Member -Name 'Server' -MemberType Noteproperty -Value $env:COMPUTERNAME
    $object | Add-Member -Name 'Current User' -MemberType Noteproperty -Value "$env:USERDOMAIN\$env:USERNAME"
    $object | Add-Member -Name 'Start Time' -MemberType Noteproperty -Value $dtStart
    $object | Add-Member -Name 'Finish Time' -MemberType Noteproperty -Value $dtEnd

    $objects += $object
    Write-Output $objects
}

function get-TestFolder([string]$testFolder)
{
    if(!(Test-Path -Path $testFolder))
    {
        $NewLogFolder = New-Item -Path $testFolder -Type Directory
        If ($NewLogFolder -ne $Null) {
            log "Created Test folder $testFolder"
        }
        else
        {
            throw "ERROR: Could not create specified test folder"
        }
    }

    Write-Output $testFolder
}

########################################################################################################
$scriptPath = "c:\users\mkrynina"
#$scriptPath = $env:USERPROFILE

Set-Location -Path $scriptPath 

. .\LoggingV2.ps1 $true $scriptPath "unitTest_Server.ps1"

try
{
    $domain = $env:USERDOMAIN
    $domainFull = $env:USERDNSDOMAIN
   
    # Results HTML file name
    $resultFile = (get-TestFolder "$scriptPath\Test") + "\UnitTest-$env:COMPUTERNAME.html"

    #################################################################################################
    $dtStart =  get-date -Format "dd-MMM-yyyy HH:mm:ss"

    log "INFO: about to call domainInfo"
    $frag1 = get-DomainInfo  | CreateHtmlFragment LIST "<h2>Domain Info</h2>"
    
    log "INFO: about to call serverInfo"
    $frag2 = get-ServerInfo | CreateHtmlFragment LIST "<h2>Server Info</h2>" 

    log "INFO: about to call volumesInfo"
    $frag3 = get-VolumesInfo | CreateHtmlFragment TABLE "<h2>Volumes Info</h2>"
    
    log "INFO: about to call certificatesInfo"
    $frag4 = get-CertificatesInfo | CreateHtmlFragment TABLE "<h2>Certificates Info</h2>" 
    
    log "INFO: about to call get-Service"
    # Leave array empty if you dont want to check any services
    $frag5 = get-Services @("DNC Client", "DHCP Client") | CreateHtmlFragment TABLE "<h2>Services</h2>" 

    log "INFO: about to call get-WebBindings"
    $frag6 = get-WebBindings | CreateHtmlFragment TABLE "<h2>IIS Info</h2><h3>Web Bindings</h3>"

    log "INFO: about to call get-IISSites"
    $frag7 = get-IISSites | CreateHtmlFragment TABLE "<h3>Sites from IIS:\Sites</h3>"

    log "INFO: about to call get-SSLBindings"
    $frag8 = get-SSLBindings | CreateHtmlFragment "TABLE" "<h3>SSL bindings from IIS:\SslBindings\0.0.0.0!443</h3>"

    $content = "$frag1 $frag2 $frag3 $frag4 $frag5 $frag6 $frag7 $frag8"

    $dtEnd =  get-date -Format "dd-MMM-yyyy HH:mm:ss"
    
    log "INFO: about to call get-CommonHeader"
    $preContent = get-CommonHeader $dtStart $dtEnd | CreateHtmlFragment LIST "<h1>Unit Testing Results on server $env:COMPUTERNAME</h1>"
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
 
    ConvertTo-HTML -head $head -PostContent $content -PreContent $preContent | Out-file $resultFile
    
    # This willopen the results file automatically. Helpfull to use in debug mode
    # Invoke-Item $resultFile
}
catch
{
    log "ERROR: $($_.Exception.Message)"
    throw "ERROR: $($_.Exception.Message)"
}

############################################################################################
# Author: Marina Krynina
# Desc: Server side Unit testing - Common  
# Updates:
#          Added windows features - Stiven
#          Added Check-WebPage - Stiven
############################################################################################

function Check-WebPage([string]$url, [string]$stringToFind)
{
    $webclient = new-object System.Net.WebClient
    $webClient.UseDefaultCredentials = $true
    $webpage = $webclient.DownloadString($url)
    if (!([string]::IsNullOrEmpty($webpage)))
    {
        if($webpage.IndexOf($stringToFind) -ge 0)
        {
            Write-Output $true
        }

        else
        {
            Write-Output $false
        }
    }
    else
    {
        Write-Output $false
    }
}

function matchServiceByName([string]$givenName, [string]$displayName, [string]$actualName)
{
    if (($actualName.ToUpper() -eq $givenName.ToUpper()) -or ($displayName.ToUpper() -eq $givenName.ToUpper()))
    {
        Write-Output $true
    }
    else
    {
        Write-Output $false
    }
}

function get-DomainInfo()
{
    try
    {
        $objects = @()
        $object = New-Object -TypeName PSObject
        $object | Add-Member -Name 'Domain' -MemberType Noteproperty -Value $env:USERDOMAIN
        $object | Add-Member -Name 'Domain FQDN' -MemberType Noteproperty -Value $env:USERDNSDOMAIN
        $objects += $object
    }
    catch
    {
        $objects = get-Exception $($_.Exception.Message)      
    }
    finally
    {
        Write-Output $objects
    }
}

Function get-ServerInfo 
{
    try
    {
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
        $object | Add-Member -Name 'IP' -MemberType Noteproperty -Value (($serverIP.IPAddress  | %{"{0:000}.{1:000}.{2:000}.{3:000}" -f @([int[]]$_.split('.'))} | sort | %{"{0}.{1}.{2}.{3}" -f @([int[]]$_.split('.'))}) -join ' | ') # cater for multiple IPs and sort in ascending order
        $object | Add-Member -Name 'Cores' -MemberType Noteproperty -Value $cpuInfo.NumberOfCores
        $object | Add-Member -Name 'Logical Processors' -MemberType Noteproperty -Value $cpuInfo.NumberOfLogicalProcessors
        $object | Add-Member -Name 'RAM (GB)' -MemberType Noteproperty -Value $memoryInGB
        # end 
    
        $objects += $object
    }
    catch
    {
        $objects = get-Exception $($_.Exception.Message)      
    }
    finally
    {
        Write-Output $objects
    }
}

function get-VolumesInfo()
{
    $objects = @()

    try
    {
        $objects = @()
        $drives = Get-WmiObject -ComputerName $env:COMPUTERNAME –Class win32_logicaldisk | Where {$_.DriveType –eq 3}
        if ($drives -eq $null)
        {
            $object = New-Object PSObject
            $object | Add-Member -MemberType NoteProperty -Name "Not Found" -Value "No drives were found"
            $objects += $object 
        }
        else
        {
            foreach($drive in $drives)
            {
                $deviceId = $drive.DeviceId
                $volumeName = $drive.VolumeName
                $totalSize = $('{0:N2}' –f ($drive.Size/1024/1024/1024))
                $freeSpace = $('{0:N2}' –f ($drive.FreeSpace/1024/1024/1024))
                $percentageFull = $('{0:N2}' –f (($totalSize - $freeSpace) / $totalSize * 100))

                $object = New-Object PSObject
                $object | Add-Member -MemberType NoteProperty -Name "Device Id" -Value $deviceId
                $object | Add-Member -MemberType NoteProperty -Name "Volume Name" -Value $volumeName
                $object | Add-Member -MemberType NoteProperty -Name "Total Size" -Value $totalSize
                $object | Add-Member -MemberType NoteProperty -Name "Free Space" -Value $freeSpace
                $object | Add-Member -MemberType NoteProperty -Name "Percentage Full" -Value $percentageFull
                $objects += $object        
            }
        }
    }
    catch
    {
        $objects = get-Exception $($_.Exception.Message)           
    }
    finally
    {
        Write-Output $objects
    }
}

function get-CertificatesInfo()
{
    $objects = @()

    try
    {
        $objects = @()
        $certs = Get-ChildItem -Recurse cert:\ -DNSName "*$env:USERDOMAIN*"
        if ($certs -eq $null)
        {
            $object = New-Object PSObject
            $object | Add-Member -MemberType NoteProperty -Name "Not Found" -Value "No certificates were found"
            $objects += $object 
        }
        else
        {
            foreach($cert in $certs)
            {
                $object = New-Object -TypeName PSObject
                $object | Add-Member -Name 'FriendlyName' -MemberType Noteproperty -Value $cert.FriendlyName
                $object | Add-Member -Name 'Thumbprint' -MemberType Noteproperty -Value $cert.Thumbprint
                $object | Add-Member -Name 'Subject' -MemberType Noteproperty -Value $cert.Subject
                $object | Add-Member -Name 'PSParentPath' -MemberType Noteproperty -Value ([string]($cert.PSParentPath)).Replace("Microsoft.PowerShell.Security\Certificate::", "")
                $objects += $object 
            }
        }
    }
    catch
    {
        $objects = get-Exception $($_.Exception.Message)           
    }
    finally
    {
        Write-Output $objects
    }
}

function get-Services ($arrayServices)
{
    $objects = @()

    try
    {
        $objects = @()
        if ($arrayServices -ne $null -and $arrayServices.Length -gt 0)
        {
            foreach($s in $arrayServices)
            {
                $svc = ([string]$s).Trim().ToUpper()
                $service = Get-WmiObject win32_service | Where-Object {matchServiceByName $svc $_.displayname $_.name} | Select Name, StartName, StartMode, State
                $objects += $service
            }
        }
        else
        {
            $services = Get-WmiObject win32_service | Select Name, StartName, StartMode, State
            $objects += $services        
        }
    }
    catch
    {
        $objects = get-Exception $($_.Exception.Message)      
    }
    finally
    {
        Write-Output $objects
    }
}

function get-WebBindings
{
    $objects = @()

    try
    {
        $objects = @()
        $webBinding = Get-WebBinding | Select protocol, bindingInformation, sslFlags, certificateHash, certificateStoreName, 
                                            @{Name="Site";Expression={ ($_.itemXPath.substring($_.itemXPath.IndexOf("@name"))).Split("'")[1]  }},
                                            @{Name="ID";Expression={ ($_.itemXPath.substring($_.itemXPath.IndexOf("@id"))).Split("'")[1]  }} -ErrorAction Stop
                                             

        if ($webBinding -eq $null)
        {
            $object = New-Object PSObject
            $object | Add-Member -MemberType NoteProperty -Name "Not Found" -Value "No web bindings were found"
            $objects += $object 
        }
        else
        {
            $objects += $webBinding
        }
    }
    catch [System.Management.Automation.CommandNotFoundException] # cater for Get-WebBinding command not be loaded
    {
        $objects = get-Exception("No Web Bindings were found.")
    }
    catch
    {
        $objects = get-Exception $($_.Exception.Message)             
    }
    finally
    {
        Write-Output $objects
    }
}

function get-IISSites
{
    $objects = @()

    try
    {
        $objects = @()
        $Websites = Get-ChildItem IIS:\Sites
        if ($Websites -eq $null)
        {
            $object = New-Object PSObject
            $object | Add-Member -MemberType NoteProperty -Name "Not Found" -Value "No IIS sites were found"
            $objects += $object 
        }
        else
        {
            foreach ($site in $Websites) 
            {
            $object = New-Object -TypeName PSObject
            $object | Add-Member -Name 'Site name' -MemberType Noteproperty -Value $site.Name
            $object | Add-Member -Name 'State' -MemberType Noteproperty -Value $site.State
            $objects += $object  
            }
        }
    }
    catch
    {
        $objects = get-Exception $($_.Exception.Message)             
    }
    finally
    {
        Write-Output $objects
    }
}

function get-SSLBindings()
{   
    try
    {
        $objects = @()
        $sslBindings = Get-Item IIS:\SslBindings\0.0.0.0!443 -ErrorAction Stop
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
    }
    catch
    {
        $objects = get-Exception $($_.Exception.Message)            
    }
    finally
    {
        Write-Output $objects
    }
}

function get-LocalGroupsAndUsers
{
    try
    {
        $objects = @()
        $objects += Get-LocalGroupMembers | select 'Local Group', Name, Type, Domain 
    }
    catch
    {
        $objects = get-Exception $($_.Exception.Message)            
    }
    finally
    {
        Write-Output $objects
    }
}

function get-WindowsFeatures
{
    try
    {
        $objects = @()

       
        $features = Get-WindowsFeature | Where {$_.Installed} | Sort FeatureType,Name | Select Name,Displayname,FeatureType,Parent
        foreach($feature in $features)
        {
            $object = New-Object -TypeName PSObject
    
            # Populate properties
            $object | Add-Member -Name 'Name' -MemberType Noteproperty -Value $feature.Name
            $object | Add-Member -Name 'DisplayName' -MemberType Noteproperty -Value $feature.DisplayName
            $object | Add-Member -Name 'FeatureType' -MemberType Noteproperty -Value $feature.FeatureType
            $object | Add-Member -Name 'Parent' -MemberType Noteproperty -Value $feature.Parent
    
            $objects += $object
        }
    }
    catch
    {
        $objects = get-Exception $($_.Exception.Message)            
    }
    finally
    {
        Write-Output $objects
    }
}

<#
===================================================================================  
DESCRIPTION:    Function enumerates members of all local groups (or a given group). 
If -Server parameter is not specified, it will query localhost by default. 
If -Group parameter is not specified, all local groups will be queried. 

AUTHOR:     Piotr Lewandowski 
VERSION:    1.0  
DATE:       29/04/2013  
SYNTAX:     Get-LocalGroupMembers [[-Server] <string[]>] [[-Group] <string[]>] 

EXAMPLES:   

Get-LocalGroupMembers -server "scsm-server" | ft -AutoSize

Server      Local Group          Name                 Type  Domain  SID
------      -----------          ----                 ----  ------  ---
scsm-server Administrators       Administrator        User          S-1-5-21-1473970658-40817565-21663372-500
scsm-server Administrators       Domain Admins        Group contoso S-1-5-21-4081441239-4240563405-729182456-512
scsm-server Guests               Guest                User          S-1-5-21-1473970658-40817565-21663372-501
scsm-server Remote Desktop Users pladmin              User  contoso S-1-5-21-4081441239-4240563405-729182456-1272
scsm-server Users                INTERACTIVE          Group         S-1-5-4
scsm-server Users                Authenticated Users  Group         S-1-5-11



"scsm-dc01","scsm-server" | Get-LocalGroupMembers -group administrators | ft -autosize

Server      Local Group    Name                 Type  Domain  SID
------      -----------    ----                 ----  ------  ---
scsm-dc01   administrators Administrator        User  contoso S-1-5-21-4081441239-4240563405-729182456-500
scsm-dc01   administrators Enterprise Admins    Group contoso S-1-5-21-4081441239-4240563405-729182456-519
scsm-dc01   administrators Domain Admins        Group contoso S-1-5-21-4081441239-4240563405-729182456-512
scsm-server administrators Administrator        User          S-1-5-21-1473970658-40817565-21663372-500
scsm-server administrators !svcServiceManager   User  contoso S-1-5-21-4081441239-4240563405-729182456-1274
scsm-server administrators !svcServiceManagerWF User  contoso S-1-5-21-4081441239-4240563405-729182456-1275
scsm-server administrators !svcscoservice       User  contoso S-1-5-21-4081441239-4240563405-729182456-1310
scsm-server administrators Domain Admins        Group contoso S-1-5-21-4081441239-4240563405-729182456-512

===================================================================================  

#>
Function Get-LocalGroupMembers
{
param(
[Parameter(ValuefromPipeline=$true)][array]$server = $env:computername,
$GroupName = $null
)
PROCESS {
    $finalresult = @()
    $computer = [ADSI]"WinNT://$server"

    if (!($groupName))
    {
    $Groups = $computer.psbase.Children | Where {$_.psbase.schemaClassName -eq "group"} | select -expand name
    }
    else
    {
    $groups = $groupName
    }
    $CurrentDomain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().GetDirectoryEntry() | select name,objectsid
    $domain = $currentdomain.name
    $SID=$CurrentDomain.objectsid
    $DomainSID = (New-Object System.Security.Principal.SecurityIdentifier($sid[0], 0)).value


    foreach ($group in $groups)
    {
    $gmembers = $null
    $LocalGroup = [ADSI]("WinNT://$server/$group,group")


    $GMembers = $LocalGroup.psbase.invoke("Members")
    $GMemberProps = @{Server="$server";"Local Group"=$group;Name="";Type="";ADSPath="";Domain="";SID=""}
    $MemberResult = @()


        if ($gmembers)
        {
        foreach ($gmember in $gmembers)
            {
            $membertable = new-object psobject -Property $GMemberProps
            $name = $gmember.GetType().InvokeMember("Name",'GetProperty', $null, $gmember, $null)
            $sid = $gmember.GetType().InvokeMember("objectsid",'GetProperty', $null, $gmember, $null)
            $UserSid = New-Object System.Security.Principal.SecurityIdentifier($sid, 0)
            $class = $gmember.GetType().InvokeMember("Class",'GetProperty', $null, $gmember, $null)
            $ads = $gmember.GetType().InvokeMember("adspath",'GetProperty', $null, $gmember, $null)
            $MemberTable.name= "$name"
            $MemberTable.type= "$class"
            $MemberTable.adspath="$ads"
            $membertable.sid=$usersid.value


            if ($userSID -like "$domainsid*")
                {
                $MemberTable.domain = "$domain"
                }

            $MemberResult += $MemberTable
            }

         }
         $finalresult += $MemberResult 
    }
    $finalresult | select server,"local group",name,type,domain,sid
    }
}

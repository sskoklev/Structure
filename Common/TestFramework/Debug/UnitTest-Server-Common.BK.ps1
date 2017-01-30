Param(
    [string] $scriptPath,
    [string] $testFolder
)

############################################################################################
# Author: Marina Krynina
# Desc: Server side Unit testing - Common  
############################################################################################

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

############################################################################################
# Main
############################################################################################
# \USER_PROFILE
#        \TestResults\SERVER-PRODUCT.html

Set-Location -Path $scriptPath 

try 
{
    Import-Module Webadministration

    $product = "Common"

    . .\LoggingV2.ps1 $true $scriptPath "unitTest-Server-$product.ps1"
    . "$scriptPath\$testFolder\HTMLGenerator.ps1"


    log "INFO: Script path $scriptPath\$testFolder"

    $dtStart =  get-date

    log "INFO: about to call domainInfo"
    $frag1 = Build-HTML-Fragment (get-DomainInfo) LIST "<h2>Domain Info</h2>"
    
    log "INFO: about to call serverInfo"
    $frag2 = Build-HTML-Fragment (get-ServerInfo) LIST "<h2>Server Info</h2>" 

    log "INFO: about to call volumesInfo"
    $frag3 = Build-HTML-Fragment (get-VolumesInfo) TABLE "<h2>Volumes Info</h2>"
    
    log "INFO: about to call certificatesInfo"
    $frag4 = Build-HTML-Fragment (get-CertificatesInfo) TABLE "<h2>Certificates Info</h2>" 
    
    log "INFO: about to call get-Service"
    # $frag5 = Build-HTML-Fragment (get-Services @("DNS Client", "DHCP Client")) TABLE "<h2>Services</h2>" 
    $frag5 = Build-HTML-Fragment (get-Services @( `
        "Cluster Service", `
        "SQL Server (MWSPCDEVICES01)", `
        "SQL Server (MWSVDS02)", `
        "SQL Server (MWSAPPSENSE03)", `
        "SQL Server (MWSMOBILITY04)", `
        "SQL Server (MWSSSRS05)", `
        "SQL Server (MWSTDT06)", `
        "SQL Server (MWSSCOM07)", `
        "SQL Server Agent (MWSPCDEVICES01)", `
        "SQL Server Agent (MWSVDS02)", `
        "SQL Server Agent (MWSAPPSENSE03)", `
        "SQL Server Agent (MWSMOBILITY04)", `
        "SQL Server Agent (MWSSSRS05)", `
        "SQL Server Agent (MWSTDT06)", `
        "SQL Server Agent (MWSSCOM07)", `
        "SQL Server Reporting Services (MWSSCOM07)", `
        "SQL Server Reporting Services (MWSSSRS05)", `
        "SQL Full-text Filter Daemon Launcher (MWSPCDEVICES01)", `
        "SQL Full-text Filter Daemon Launcher (MWSVDS02)", `
        "SQL Full-text Filter Daemon Launcher (MWSAPPSENSE03)", `
        "SQL Full-text Filter Daemon Launcher (MWSMOBILITY04)", `
        "SQL Full-text Filter Daemon Launcher (MWSSSRS05)", `
        "SQL Full-text Filter Daemon Launcher (MWSTDT06)", `
        "SQL Full-text Filter Daemon Launcher (MWSSCOM07)" `
        )) TABLE "<h2>Services</h2>" 

    log "INFO: about to call get-WebBindings"
    $frag6 = Build-HTML-Fragment (get-WebBindings) TABLE "<h2>IIS Info</h2><h3>Web Bindings</h3>"

    log "INFO: about to call get-IISSites"
    $frag7 = Build-HTML-Fragment (get-IISSites) TABLE "<h3>Sites from IIS:\Sites</h3>"

    log "INFO: about to call get-SSLBindings"
    $frag8 = Build-HTML-Fragment (get-SSLBindings) TABLE "<h3>SSL bindings from IIS:\SslBindings\0.0.0.0!443</h3>"

    $content = "$frag1 $frag2 $frag3 $frag4 $frag5 $frag6 $frag7 $frag8"

    Build-HTML-UnitTestResults $content $dtStart $product "$scriptPath\$testFolder"

    exit 0
}
catch
{
    log "ERROR: $($_.Exception.Message)"

    # This is done to get an error code from the scheduled task.
    Write-Output  $($_.Exception.Message) | Out-File "$scriptPath\error.txt" -Append
    exit -1
}
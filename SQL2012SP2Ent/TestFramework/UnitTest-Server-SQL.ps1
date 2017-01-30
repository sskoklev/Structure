Param(
    [string] $scriptPath,
    [string] $testFolder
)

############################################################################################
# Author: Marina Krynina
# Desc: Server side Unit testing - Template and Sample  
############################################################################################

Import-Module FailoverClusters

function get-MWSRegistry
{  
    try
    {
        $objects = @()
        
        $RootLocation = "Registry::HKEY_LOCAL_MACHINE\Software" 
        $CustomNode = "MWS2" 

        $hiveMWS2Location = $RootLocation + '\' + $CustomNode

        $nodes = Get-ItemProperty -Path $hiveMWS2Location 

        log "INFO: The following nodes exist within '$hiveMWS2Location': $nodes"

        foreach($node in $nodes)
        {
            $object = New-Object -TypeName PSObject
    
            # Populate properties
            $object | Add-Member -Name 'IsSharedDiskConfigured' -MemberType Noteproperty -Value (AddColor $node.IsSharedDiskConfigured "False" "Red") 
            $object | Add-Member -Name 'IsWindowsClusterConfigured' -MemberType Noteproperty -Value (AddColor $node.IsWindowsClusterConfigured "False" "Red") 
            $object | Add-Member -Name 'IsSQLClusterConfigured' -MemberType Noteproperty -Value (AddColor $node.IsSQLClusterConfigured "False" "Red") 
    
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

function get-WindowsCluster
{  
    try
    {
        $objects = @()
        $object = New-Object -TypeName PSObject
        
        $clusterExists = Get-Cluster

        $nodes = Get-ClusterNode

        $clusterNetwork = Get-ClusterNetwork

        # Populate properties
        $object | Add-Member -Name 'Cluster Name' -MemberType Noteproperty -Value $clusterExists.Name
        $object | Add-Member -Name 'Cluster Domain' -MemberType Noteproperty -Value $clusterExists.Domain
        $object | Add-Member -Name 'Cluster Description' -MemberType Noteproperty -Value $clusterExists.Description

        $nodeCount = 0
        foreach($node in $nodes)
        {
            $isNodeRunning = AddColor $node.State "Down" "red"
            $nodecount += 1
            $object | Add-Member -Name "Node$($nodecount)" -MemberType Noteproperty -Value "$($node.Name) ($($isNodeRunning))"
        }

        $isClusterNetworkRunning = AddColor $clusterNetwork.State "Down" "red"
        $object | Add-Member -Name 'Cluster Network' -MemberType Noteproperty -Value "$($clusterNetwork.Name) ($($isClusterNetworkRunning))"
         
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


function get-WindowsClusterResources
{  
    try
    {
        $objects = @()
        
        $clusterExists = Get-Cluster

        $nodeResources = Get-ClusterResource | Sort-Object ResourceType, Name

        $nodeCount = 0
        foreach($nodeResource in $nodeResources)
        {
            $nodecount += 1

            $object = New-Object -TypeName PSObject
    
            $object | Add-Member -Name "Name" -MemberType Noteproperty -Value $nodeResource.Name
            $object | Add-Member -Name "State" -MemberType Noteproperty -Value (AddColor $($nodeResource.State) "Offline" "red" )
            $object | Add-Member -Name "OwnerGroup" -MemberType Noteproperty -Value $nodeResource.OwnerGroup
            $object | Add-Member -Name "ResourceType" -MemberType Noteproperty -Value $nodeResource.ResourceType
  
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

function get-WindowsClusterDisks
{  
    try
    {
        $objects = @()
        
        $clusterDisks = Get-ClusterResource | ? { $_.ResourceType.Name -eq "Physical Disk" } | % {
              $resourceName = $_.Name

              $resource  = gwmi MSCluster_Resource -Namespace root/mscluster |
                           ? { $_.Name -eq $resourceName }
              $disk      = gwmi -Namespace root/mscluster -Query `
                           "ASSOCIATORS OF {$resource} WHERE ResultClass=MSCluster_Disk"
              $partition = gwmi -Namespace root/mscluster -Query `
                           "ASSOCIATORS OF {$disk} WHERE ResultClass=MSCluster_DiskPartition"

              $partition | select Path, VolumeLabel 
            }

        $nodeCount = 0
        foreach($clusterDisk in ($clusterDisks | Sort-Object Path))
        {
            $nodecount += 1

            $object = New-Object -TypeName PSObject
    
            $object | Add-Member -Name "Path" -MemberType Noteproperty -Value $clusterDisk.Path
            $object | Add-Member -Name "VolumeLabel" -MemberType Noteproperty -Value $clusterDisk.VolumeLabel
  
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

function get-SCCMRequirements
{  
    try
    {
        $objects = @()
        
        $drives = Get-PSDrive -PSProvider 'FileSystem'

        foreach ($drive in $drives) 
        {   
            $driveLetter = $drive.Root
            $file = "$($driveLetter)NO_SMS_ON_DRIVE.sms"
            
            $object = New-Object -TypeName PSObject
            If (Test-Path $file)
            {
              # // File exists
              $fileExists = "Yes"
            }Else
            {
              # // File does not exist
              $fileExists = "No"
            }

            $object | Add-Member -Name "Path" -MemberType Noteproperty -Value $driveLetter
            $object | Add-Member -Name "NO_SMS_ON_DRIVE.sms exists?" -MemberType Noteproperty -Value (AddColor $fileExists "No" "Red")

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

function GetSQLPort([string] $SQlcompname, [string] $SQLInstance )
{
    # Load the assemblies
    [system.reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")|Out-Null
    [system.reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.SqlWmiManagement")|Out-Null
    $mc = new-object Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer $SQlcompname
    $i=$mc.ServerInstances[$SQLInstance]
    $p=$i.ServerProtocols['Tcp']
    $ip= $p.IPAddresses | Where-Object {$_.Name -eq "IPAll"}
    $portNumber = $ip.IPAddressProperties["TcpPort"].Value
    Write-Output $portNumber    
}

function get-SQLInstances
{  
    try
    {
        $objects = @()
        
        $sqlInstances = Get-SQLInstance -ComputerName $env:COMPUTERNAME


        foreach ($sqlInstance in $sqlInstances) 
        {   
            $portNumber = GetSQLPort $sqlInstance.ComputerName $sqlInstance.SqlInstance
            $object = New-Object -TypeName PSObject

            $object | Add-Member -Name "Name" -MemberType Noteproperty -Value $sqlInstance.FullName
            $object | Add-Member -Name "Edition" -MemberType Noteproperty -Value "$($sqlInstance.Caption) : $($sqlInstance.Edition)"
            $object | Add-Member -Name "Version" -MemberType Noteproperty -Value $sqlInstance.Version
            $object | Add-Member -Name "Is Clustered?" -MemberType Noteproperty -Value (AddColor $sqlInstance.IsClusterNode "False" "Red") 
            $object | Add-Member -Name "Static Port #" -MemberType Noteproperty -Value $portNumber

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
                # note that only part of the service name is passed in. this is to allow this function to support multiple
                # servers without needing to have a custom function per cluster
                $services = Get-WmiObject win32_service | Where-Object {$_.name -like "*$($svc)*"}
                foreach($service in $services)
                {
 
                    $object = New-Object -TypeName PSObject

                    $object | Add-Member -Name "Name" -MemberType Noteproperty -Value $($service.Name)
                    $object | Add-Member -Name "StartName" -MemberType Noteproperty -Value $($service.StartName)
                    $object | Add-Member -Name "StartMode" -MemberType Noteproperty -Value (AddColor $service.StartMode "Auto" "Red")
                    $object | Add-Member -Name "State" -MemberType Noteproperty -Value  (AddColor $service.State "Stopped" "Red") 
              
                    $objects += $object
                }
            }
        }
        else
        {
            $services = Get-WmiObject win32_service
            
            foreach($service in $services)
            {    
                $object = New-Object -TypeName PSObject

                $object | Add-Member -Name "Name" -MemberType Noteproperty -Value $($service.Name)
                $object | Add-Member -Name "StartName" -MemberType Noteproperty -Value $($service.StartName)
                $object | Add-Member -Name "StartMode" -MemberType Noteproperty -Value (AddColor $service.StartMode "Auto" "Red")
                $object | Add-Member -Name "State" -MemberType Noteproperty -Value  (AddColor $service.State "Stopped" "Red") 
              
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

############################################################################################
# Main
############################################################################################
# \USER_PROFILE
#        \TestResults\SERVER-PRODUCT.html

Set-Location -Path $scriptPath 


. .\Get-SQLInstance.ps1

try
{
    . .\ConfigureMWS2Registry.ps1

    # Step 1 - Change product value
    $product = "SQL Cluster"

    . "$scriptPath\$testFolder\HTMLGenerator.ps1"
    . .\LoggingV2.ps1 $true $scriptPath "unitTest-Server-$product.ps1"
    
    log "INFO: Script path $scriptPath"

    $dtStart =  get-date

    # check if cluster exists. If not no point in doing anymore tests    
    $clusterExists = Get-Cluster
    if ($clusterExists -eq $null)
    {
        $object = New-Object PSObject
        $object | Add-Member -MemberType NoteProperty -Name "Not Found" -Value "No Windows Cluster was found"
        $objects += $object
            
        $content = Build-HTML-Fragment ($objects) LIST "<h2>Windows Cluster</h2>" 
   }
    else
    {
        # Step 2 - Call the test functions here
        log "INFO: about to call get-MWSRegistry"
        $frag1 = Build-HTML-Fragment (get-MWSRegistry) LIST "<h2>MWS Registry</h2>" 
        log "INFO: about to call get-WindowsCluster"
        $frag2 = Build-HTML-Fragment (get-WindowsCluster) LIST "<h2>Windows Cluster</h2>" 
        log "INFO: about to call get-WindowsClusterDisks"
        $frag3 = Build-HTML-Fragment (get-WindowsClusterDisks) TABLE "<h2>Windows Cluster Disks</h2>" 
        log "INFO: about to call get-WindowsClusterResources"
        $frag4 = Build-HTML-Fragment (get-WindowsClusterResources) TABLE "<h2>Windows Cluster Resources</h2>" 
        log "INFO: about to call get-SCCMRequirements"
        $frag5 = Build-HTML-Fragment (get-SCCMRequirements) TABLE "<h2>SCCM Requirements</h2>" 
        log "INFO: about to call get-SQLInstances"
        $frag6 = Build-HTML-Fragment (get-SQLInstances) TABLE "<h2>SQL Instances</h2>" 
        log "INFO: about to call get-Services"
        $frag7 = Build-HTML-Fragment (get-Services @( `
                'ClusSvc', `
                'MSSQL$', `
                'SQLAgent$', `
                'MSSQLFDLauncher$' `
            )) TABLE "<h2>Services</h2>" 


        # Step 3 - Populate content
        $content = "$frag1 $frag2 $frag3 $frag4 $frag5 $frag6 $frag7"

    }

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
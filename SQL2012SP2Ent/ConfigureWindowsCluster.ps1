Param(
    [string] $scriptPath,
    [string] $clusterXMLfile,
    [string] $currentUser
)


#########################################################################
# Author: Stiven Skoklevski,
# Create and configure the Windows Cluster
#########################################################################

Import-Module FailoverClusters

###########################################
# Create Cluster with Primary Node only
###########################################
function CreateCluster()
{
    log "INFO: Creating cluster $clusterName utilising nodes $primaryNode on static IP $clusterIP."

    # done in 2 steps to ensure that the primary  node is assigned a cluster ID of 1.
    # A cluster ID of 1 ensures that this node is considered the primary node          
    New-Cluster -Name $clusterName  -Node $primaryNode  -StaticAddress $clusterIP -NoStorage 
    Start-Sleep -Seconds 10
    log "INFO: Primary node: '$primaryNode' has been added."

    log "INFO: Created cluster $clusterName utilising nodes $primaryNode on static IP $clusterIP."
}

###########################################
# Create Cluster with Secondary Node only
###########################################
function AddSecondaryNode()
{
    log "INFO: Adding node '$secondaryNode' to cluster '$clusterName'."
        
    Get-Cluster | Add-ClusterNode -Name $secondaryNode -NoStorage
    Start-Sleep -Seconds 10

    log "INFO: Added node '$secondaryNode' to cluster '$clusterName'."
}

###########################################
# Grant Cluster Permissions
###########################################
function GrantClusterPermissions()
{

    $domain = get-domainshortname
    $adminUser = (Get-VariableValue $ADMIN "agilitydeploy" $true)

    log "INFO: Granting $domain\$adminUser full permissions to the cluster '$clusterName'."
    Grant-ClusterAccess -User $domain\$adminUser -Full
    log "INFO: Granted $domain\$adminUser full permissions to the cluster '$clusterName'."
    
    log "INFO: Granting $currentUser full permissions to the cluster '$clusterName'."
    Grant-ClusterAccess -User $currentUser -Full
    log "INFO: Granted $currentUser full permissions to the cluster '$clusterName'."
}

###########################################
# Configure Cluster
###########################################
function ConfigureCluster()
{
    log "INFO: Configuring cluster."

    log "INFO: Updating Cluster Network Name from 'Cluster Network 1' to $clusterNetwork."
    $network = Get-ClusterNetwork 'Cluster Network 1'
    $network.Name = $clusterNetwork
    $network.Role = 3 # Enabled for client and cluster communication

    log "INFO: Updating Cluster Network Name from 'Cluster Network 2' to $managementIPName."
    $network = Get-ClusterNetwork 'Cluster Network 2'
    $network.Name = $managementIPName
    $network.Role = 0 # Disabled for cluster communication


    log "INFO: Updating Cluster IP Address Name from 'Cluster IP Address' to $clusterIPName."
    $ipResource = Get-ClusterResource | Where-Object {$_.ResourceType -eq 'IP Address'}
    $ipResource.Name = $clusterIPName

    log "INFO: Updating Cluster description to $clusterDescription."
    $c = Get-Cluster
    $c.Description = $clusterDescription

    log "INFO: Configured cluster."
}

###########################################
# Configure Disks
###########################################
function ConfigureDisks()
{
    log "INFO: Configuring clustered available disks."

    # Add all available disks
    Get-ClusterAvailableDisk | Add-ClusterDisk

    log "INFO: Renaming cluster disks to be the same as the volume labels."
    $ClusterDisks =  (Get-CimInstance -ClassName MSCluster_Resource -Namespace root/mscluster -Filter "type = 'Physical Disk'") | Sort-Object Name
    foreach ($Disk in $ClusterDisks) 
    {
        $DiskResource = Get-CimAssociatedInstance -InputObject $Disk -ResultClass MSCluster_DiskPartition

        if (-not ($DiskResource.VolumeLabel -eq $Disk.Name)) 
        {
            log "INFO: Renaming $($Disk.Name) to $($DiskResource.VolumeLabel)."
            Invoke-CimMethod -InputObject $Disk -MethodName Rename -Arguments @{newName = $DiskResource.VolumeLabel}
        }

    }

    log "INFO: Configured clustered available disks."
}

###########################################
# Configure Witness
###########################################
function ConfigureWitness()
{
    log "INFO: Configuring Witness/Quorum on Disk named $witnessDiskName."
    # Configure Witness/Quorum
    Start-Sleep -Seconds 5
    Set-ClusterQuorum -NodeAndDiskMajority $witnessDiskName

    log "INFO: Configured Witness/Quorum on Disk named $witnessDiskName."
}

###########################################
# Validate Cluster - The SQL Cluster install will not pass pre-reqs if the cluster is not validated
###########################################
function ValidateCluster()
{
    log "INFO: Validating the cluster: '$clusterName'."
    # Configure Witness/Quorum
    Start-Sleep -Seconds 5
    $currentDate = get-date -Format yyyyMMddHHmm
    $testReport = "$scriptPath\Logs\ClusterValidation_$($clusterName)_$currentDate.html"
    Test-Cluster -ReportName $testReport
    Start-Sleep -Seconds 20

    log "INFO: Validated the cluster: '$clusterName'. See validation report: '$testReport'"
}

###########################################
# Main
###########################################

Set-Location -Path $scriptPath 

 # Logging must be configured here. otherwise it gets lost in the nested calls# 
 . .\LoggingV2.ps1 $true $scriptPath "ConfigureWindowsCluster.ps1"

. .\PlatformUtils.ps1
. .\VariableUtility.ps1

if([String]::IsNullOrEmpty($clusterXMLfile))
{
   log "ERROR: The clusterXMLfile parameter is null or empty."
}
else
{
    # *** configure and validate existence of input file
    $inputFile = "$scriptPath\$clusterXMLfile"

    if ((CheckFileExists( $inputFile)) -ne $true)
    {
        log "ERROR: $inputFile is missing, users will not be configured."
        return
    }

    log "INFO: ***** Executing $clusterXMLfile ***********************************************************"

    # Get the xml Data
    $xml = [xml](Get-Content $clusterXMLfile)
 
    $nodes = $xml.SelectNodes("//doc/WindowsCluster")
    
    if (([string]::IsNullOrEmpty($nodes)))
    {
        log "No cluster settings to configure in: '$clusterXMLfile'"
        return
    }


    foreach ($node in $nodes) 
    {
        $clusterName = ([string](Get-ServerName $node.GetAttribute("ClusterName"))).ToUpper() 
        $clusterDescription = $node.GetAttribute('ClusterDescription') 
        $primaryNode = ([string](Get-ServerName $node.GetAttribute("PrimaryNode"))).ToUpper() 
        $secondaryNode = ([string](Get-ServerName $node.GetAttribute('SecondaryNode'))).ToUpper()
        $clusterIP = $node.GetAttribute('ClusterIP')
        $clusterNetwork = ([string](Get-ServerName $node.GetAttribute('ClusterNetwork'))).ToUpper()
        $clusterIPName = ([string](Get-ServerName $node.GetAttribute('ClusterIPName'))).ToUpper()
        $witnessDiskName = $node.GetAttribute('WitnessDiskName')
        $managementIPName = $node.GetAttribute('ManagementIPName')

        if([String]::IsNullOrEmpty($clusterName))
        {
            log "ERROR: clusterName is empty."
            return                            
        }


        if([String]::IsNullOrEmpty($primaryNode))
        {
            log "ERROR: primaryNode is empty."
            return                            
        }


        if([String]::IsNullOrEmpty($secondaryNode))
        {
            log "ERROR: secondaryNode is empty."
            return                            
        }


        if([String]::IsNullOrEmpty($clusterIP))
        {
            log "ERROR: clusterIP is empty."
            return                            
        }


        if([String]::IsNullOrEmpty($clusterNetwork))
        {
            log "ERROR: clusterNetwork is empty."
            return                            
        }


        if([String]::IsNullOrEmpty($clusterIPName))
        {
            log "ERROR: clusterIPName is empty."
            return                            
        }


        if([String]::IsNullOrEmpty($witnessDiskName))
        {
            log "ERROR: witnessDiskName is empty."
            return                            
        }

        if([String]::IsNullOrEmpty($managementIPName))
        {
            log "ERROR: managementIPName is empty."
            return                            
        }

        $clusterExists = Get-Cluster
        if($clusterExists -ne $null)
        {
            log "INFO: The cluster '$clusterName' already exists and will not be recreated."
        }
        else
        {
            CreateCluster

            GrantClusterPermissions

            ConfigureCluster

            ConfigureDisks

            ConfigureWitness

            # Add secondary node at the end to ensure drive letters arer assigned to cluster disk 
            # are in accordance with what is assigned to actual disks
            AddSecondaryNode

            ValidateCluster
        }
    }

}

Param(
    [string] $scriptPath,
    [string] $clusterNames,
    [string] $currentUser
)

#########################################################################
# Author: Stiven Skoklevski,
# Prestage the AD Computer objects required by the Cluster Objects 
# and assign these objects the CreateChild permission.
#########################################################################

###########################################
# Assign CreateChild Permissions
###########################################
function AssignPermissions([string]$clusterObject, [string]$parentOU)
{
    log "INFO: Assigning CreateChild permission to $($clusterObject) in $($parentOU)"

    $acl = get-acl "ad:$($parentOU)"

    # $acl.access #to get access right of the OU

    $computer = get-adcomputer $clusterObject

    $sid = [System.Security.Principal.SecurityIdentifier] $computer.SID

    # Create a new access control entry to allow access to the OU

    $identity = [System.Security.Principal.IdentityReference] $SID

    $adRights = [System.DirectoryServices.ActiveDirectoryRights] "CreateChild"

    $type = [System.Security.AccessControl.AccessControlType] "Allow"

    $inheritanceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance] "All"

    $ACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $identity,$adRights,$type,$inheritanceType

    # Add the ACE to the ACL, then set the ACL to save the changes

    $acl.AddAccessRule($ace)

    Set-acl -aclobject $acl "ad:$($parentOU)"

    log "INFO: Assigned CreateChild permission to $($clusterObject) in $($parentOU)"
}

###########################################
# Create the AD Computer Objects
###########################################
function CreateADObjects([string]$clusterObjects)
{
    $clusters = $clusterObjects.Split(";", [StringSplitOptions]::RemoveEmptyEntries)

    foreach($cluster in $clusters)
    {
        $validClusterName = $cluster -match "[CLN]-\d{3}" 
        if($validClusterName -eq $false)
        {
            log "ERROR: The cluster name $cluster is not a valid format. Format must be 'CLN-NNN' for example, 'CLN-123'."
            log "******************"
            continue
        }

        $clusterName = ([string](Get-ServerName $cluster)).ToUpper() 

        # cluster objects wont exist yet so use current server
        $dnsDomain = get-domainname
        log "domain: $dnsDomain"
        $domainSplit = $dnsDomain.split(".")
        
        # assumption is that this will be the same across all environments
        $OU = "OU=Database,OU=Servers,OU=Customer,DC=$($domainSplit[0]),DC=$($domainSplit[1]),DC=$($domainSplit[2])"
        log "******************"
        log "INFO: Creating AD Object $clusterName in the OU: '$OU'"

        try
        {
            $computerExists = Get-ADComputer $clusterName -ErrorAction Stop
            log "WARN: The computer object $clusterName already exists and will not be recreated."
            log "******************"
            continue
        }
        catch
        {
            log "INFO: The computer object $clusterName will be created."
        }

        # new computer object has to be disabled otherwise cluster creation will fail.
        New-ADComputer –Name $clusterName `
                        –SAMAccountName $clusterName `
                        -DisplayName $clusterName `
                        -Path $OU `
                        -Enabled $false `
                        -PasswordNeverExpires $true `
                        -Description "Failover cluster virtual network name account"

        log "INFO: Created AD Object $clusterName in the OU: '$OU'"
        $parentOU = "OU=Servers,OU=Customer,DC=$($domainSplit[0]),DC=$($domainSplit[1]),DC=$($domainSplit[2])"
        AssignPermissions $clusterName $parentOU
    }
}

###########################################
# Main
###########################################

Set-Location -Path $scriptPath 

. .\LoggingV2.ps1 $true $scriptPath "PreStageClusterADObjects.ps1"

. .\PlatformUtils.ps1
. .\VariableUtility.ps1

log "INFO: Creating Cluster AD Objects for '$clusterNames'"    

CreateADObjects $clusterNames

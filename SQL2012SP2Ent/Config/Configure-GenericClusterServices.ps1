Param(
    [string]$scriptPath,
    [string]$GENERICSERVICEXMLFILE 
)

#########################################################################
# Author: Stiven Skoklevski, CSC
# Create generic cluster services. For example this is:
# - for the SSRS service and associated Cluster Name/IP
# - not roles for SQL DB instance
#########################################################################


$genServiceXMLfile = $GENERICSERVICEXMLFILE
if([String]::IsNullOrEmpty($genServiceXMLfile))
{
    log "ERROR: The genericServiceXMLfile parameter is null or empty."
}
else
{
    # *** configure and validate existence of input file
    $inputFile = "$scriptPath\$genServiceXMLfile"

    if ((CheckFileExists( $inputFile)) -ne $true)
    {
        log "ERROR: $inputFile is missing, users will not be configured."
        return
    }

    log "INFO: ***** Executing $genServiceXMLfile ***********************************************************"

    # Get the xml Data
    $xml = [xml](Get-Content $genServiceXMLfile)
 
    $nodes = $xml.SelectNodes("//doc/GenericClusterService")
    
    if (([string]::IsNullOrEmpty($nodes)))
    {
        log "No generic cluster service settings to configure in: '$genServiceXMLfile'"
        return
    }

    foreach ($node in $nodes) 
    {
        $clusterName = ([string](Get-ServerName $node.GetAttribute("ClusterName"))).ToUpper() 
        $serviceName = ([string](Get-ServerName $node.GetAttribute("ServiceName"))).ToUpper() 
        $dependantService = $node.GetAttribute('DependantService')
        $staticIP = $node.GetAttribute('StaticIP')

        if([String]::IsNullOrEmpty($clusterName))
        {
            log "ERROR: clusterName is empty."
            return                            
        }

        if([String]::IsNullOrEmpty($serviceName))
        {
            log "ERROR: serviceName is empty."
            return                            
        }

        if([String]::IsNullOrEmpty($dependantService))
        {
            log "ERROR: dependantService is empty."
            return                            
        }

        if([String]::IsNullOrEmpty($staticIP))
        {
            log "ERROR: staticIP is empty."
            return                            
        }

        $dependantServiceExists = Get-Service -Name $dependantService -ErrorAction SilentlyContinue
        if ($dependantServiceExists -eq $null)
        {
            log "WARN: The dependant service '$dependantService' does not exist."
            return
        }

        $clusterServiceExists = Get-ClusterResource -Name $serviceName -ErrorAction SilentlyContinue
        if($clusterServiceExists -eq $null)
        {
            try
            {
                $computerExists = Get-ADComputer $serviceName -ErrorAction Stop
                log "WARN: The computer object $serviceName already exists and will not be recreated. Either delete (after confirming it is not required) $serviceName from AD or correct the relevant XML file."
                log "******************"
                return
            }
            catch
            {
                log "WARN: The computer object $serviceName DOES NOT already exist and will be created."
            }

            log "INFO: Creating the generic cluster service '$serviceName'."


            Get-Cluster | `
            Add-ClusterGenericServiceRole `
                -ServiceName $dependantService `
                -Name $serviceName `
                -StaticAddress $staticIP

            log "INFO: Created the generic cluster service '$serviceName'."
        }
        else
        {
            log "WARN: The generic cluster service '$serviceName' already exists and will not be recreated."
        }
    }
}

Param(
    [string]$scriptPath,
    [string]$SQLPORTSXMLFILE     # cater for multiple DB servers eg, Shared and SharePoint
)

#########################################################################
# Author: Stiven Skoklevski, CSC
# Assign static ports to DB instances
#########################################################################
  
function AlterSQLPort([string] $SQlcompname, [string] $SQLInstance, [int] $portnumber )
{
    # Load the assemblies
    [system.reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")|Out-Null
    [system.reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.SqlWmiManagement")|Out-Null
    $mc = new-object Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer $SQlcompname
    $i=$mc.ServerInstances[$SQLInstance]
    $p=$i.ServerProtocols['Tcp']
    foreach($ipAddress in $p.IPAddresses)
    {
        $ipAddress.IPAddressProperties['TcpDynamicPorts'].Value = ''
    }
    $ip=$p.IPAddresses['IPAll']
    $ip.IPAddressProperties['TcpDynamicPorts'].Value = ''
    $ipa=$ip.IPAddressProperties['TcpPort']
    $ipa.Value = [string]$portnumber
    $p.Alter()

    log "SUCCESS: SQL Server TCP Port on DB instance '$SQLInstance' has been reconfigured to static port - $portnumber."

}

function RestartSQLService([string] $SQLInstance)
{
   $SQLServicename = "MSSQL$"+$SQLInstance
   $AgentServiceName = "SQLAgent$"+$SQLInstance

   log "INFO: Restarting $($SQLServicename) and $($AgentServiceName)"
   Restart-Service $SQLServicename, $AgentServiceName -Force
   Start-Sleep -Seconds 10
}

function ConfigureSQLPorts()
{
    # current computer
    $serverName = $env:COMPUTERNAME

    # Get the xml Data
    $xml = [xml](Get-Content $inputFile)

    log "INFO: Stop all SQL and SQL Agent resources."
    $resources = Get-ClusterResource | Where-Object {$_.resourceType -eq 'SQL Server' -or $_.ResourceType -eq 'SQL Server Agent'} | Stop-ClusterResource
    Start-Sleep -Seconds 10
    log "INFO: The following resources were stopped: $resources"

    $nodes = $xml.SelectNodes("//*[@SQLInstanceName]")

    if (([string]::IsNullOrEmpty($nodes)))
    {
        log "No port settings to configure in: '$inputFile'"
        return
    }


    foreach ($node in $nodes) 
    {
        try
        {
            $SQLInstanceName = $node.attributes['SQLInstanceName'].value
            $portnumber = $node.attributes['PortNumber'].value

            if (([string]::IsNullOrEmpty($SQLInstanceName)))
            {
                log "WARNING: SQLInstanceName is missing, skipping the record"
                continue
            }

            if (([string]::IsNullOrEmpty($portnumber)))
            {
                log "WARNING: PortNumber is missing, skipping the record"
                continue
            }

            log "INFO: Server $serverName, Instance $SQLInstanceName, PortNumber $portnumber"
            AlterSQLPort $serverName $SQLInstanceName $portnumber

            log "INFO: Server $serverName, Instance $SQLInstanceName, PortNumber $portnumber"
            RestartSQLService $SQLInstanceName    
        }
        Catch
        {
            $ex = $_.Exception | format-list | Out-String
            log "ERROR: $ex"
        }
    }

    log "INFO: Start all SQL and SQL Agent resources"
    $resources = Get-ClusterResource | Where-Object {$_.resourceType -eq 'SQL Server' -or $_.ResourceType -eq 'SQL Server Agent'} | Start-ClusterResource
    Start-Sleep -Seconds 10
    log "INFO: The following resources were started: $resources"
}

###########################################
# Main 
###########################################

if (([string]::IsNullOrEmpty($SQLPORTSXMLFILE)))
{
    log "ERROR: SQLPORTSXMLFILE is missing, SQL portss will not be configured."
    return
}

# *** configure and validate existence of input file
$inputFile = "$scriptPath\$SQLPORTSXMLFILE"

if ((CheckFileExists( $inputFile)) -ne $true)
{
    log "ERROR: $inputFile is missing, SQL portss will not be configured."
    return
}

ConfigureSQLPorts

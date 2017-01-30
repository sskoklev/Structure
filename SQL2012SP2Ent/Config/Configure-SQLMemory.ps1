Param(
    [string]$scriptPath,
    [string]$SQLMEMORYXMLFILE     # cater for multiple DB servers eg, Shared and SharePoint
)

#########################################################################
# Author: Stiven Skoklevski, CSC
# Assign min/max memory to DB instances
#########################################################################


#########################################################################
# Get total amount of memory available to the server
#########################################################################
function GetSQLMaxMemory()
{
    $mem = Get-WMIObject -class Win32_PhysicalMemory `
                     | Measure-Object -Property capacity -Sum 
    $memtotal = ($mem.Sum / 1MB);

    return $memtotal ;
}
  
#########################################################################
# Set the min/max memory available to the DB INstance
#########################################################################
function SetSQLInstanceMemory ( 
    [string]$SQLInstanceName = ".", 
    [int]$minMem = $null, 
    [int]$maxMem = $null) 
{
    [system.reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")|Out-Null
    $srv = new-object Microsoft.SQLServer.Management.Smo.Server($SQLInstanceName)
    $srv.ConnectionContext.LoginSecure = $true

    $srv.Configuration.MinServerMemory.ConfigValue = $minMem
    $srv.Configuration.MaxServerMemory.ConfigValue = $maxMem

    $srv.Configuration.Alter()
}

#########################################################################
# Configure SQL Memory
#########################################################################
function ConfigureSQLMemory()
{
    # Get the xml Data
    $xml = [xml](Get-Content $inputFile)

    $maxServerMemory = GetSQLMaxMemory

    $OSMemorynodes = $xml.SelectNodes("//doc/OSMemoryConfig/Mem")
    if (([string]::IsNullOrEmpty($OSMemorynodes)))
    {
        log "No memory node settings to configure in: '$inputFile'"
        return
    }

    $percentageReserved = $OSMemorynodes.GetAttribute("PercentageReserved")
    if (([string]::IsNullOrEmpty($percentageReserved)))
    {
        log "WARNING: percentageReserved is missing, defaulting to reserve 10% of total server memory."
        $percentageReserved = "10"
    }
 
    # percentage reserved for OS
    $percentage = 1 - ([int]$percentageReserved / 100)

    $sql_mem = $maxServerMemory * $percentage ;
    $sql_mem -= ($sql_mem % 1024) ;  

    # memory reserved for OS
    $svr_mem = $maxServerMemory - $sql_mem

    $nodes = $xml.SelectNodes("//doc/SQLMemoryConfig/Mem")

    if (([string]::IsNullOrEmpty($nodes)))
    {
        log "No memory settings to configure in: '$inputFile'"
        return
    }

    # get total Memory required for DB instances
    $memRequired = 0
    foreach ($node in $nodes) 
    {
        $memRequired += [int]$node.GetAttribute("Min")
    }

    $dbInstanceCount = $nodes.Count

    # this additional amount + minimum will be used as max memory setting
    $additionalMemory = ([int]$maxServerMemory - ([int]$memRequired + [int]$svr_mem))/ [int]$dbInstanceCount

    if($maxServerMemory -le ($memRequired + $svr_mem))
    {
       log "WARN: Total available server memory is:'$maxServerMemory',  Memory required for SQL Instances is:'$memRequired', Memory reserved for OS is:'$svr_mem'. There is not availabe memory so min/max memory settings will not be applied."
       return
    }

    log "INFO: Max Server Memory Available: '$maxServerMemory', Server Reserved Memeory: '$svr_mem', Number of DB Instances: '$dbInstanceCount', Additional Memory: '$additionalMemory'"

    foreach ($node in $nodes) 
    {
        try
        {
            $clusterNetworkName = ([string](Get-ServerName $node.GetAttribute("ClusterNetworkName"))).ToUpper() 
            $SQLInstanceName = $node.GetAttribute("SQLInstanceName")
            $minMemory = $node.GetAttribute("Min")
            if (([string]::IsNullOrEmpty($clusterNetworkName)))
            {
                log "WARNING: clusterNetworkName is missing, skipping the record"
                continue
            }

            if (([string]::IsNullOrEmpty($SQLInstanceName)))
            {
                log "WARNING: SQLInstanceName is missing, skipping the record"
                continue
            }

            if (([string]::IsNullOrEmpty($minMemory)))
            {
                log "WARNING: minMemory is missing, skipping the record"
                continue
            }

            $maxMemory = [int]$minMemory + [int]$additionalMemory

            log "INFO: Setting Cluster $clusterNetworkName, Instance $SQLInstanceName, Minimum Memory $minMemory, Maximum Memory $maxMemory"
            SetSQLInstanceMemory "$clusterNetworkName\$SQLInstanceName" $minMemory $maxMemory
            log "INFO: Set Cluster $clusterNetworkName, Instance $SQLInstanceName, Minimum Memory $minMemory, Maximum Memory $maxMemory"
        }
        Catch
        {
            $ex = $_.Exception | format-list | Out-String
            log "ERROR: $ex"
        }
    }
}

###########################################
# Main 
###########################################

try
{
    if (([string]::IsNullOrEmpty($SQLMEMORYXMLFILE)))
    {
        log "ERROR: SQLMEMORYXMLFILE is missing, SQL portss will not be configured."
        return
    }

    # *** configure and validate existence of input file
    $inputFile = "$scriptPath\$SQLMEMORYXMLFILE"

    if ((CheckFileExists( $inputFile)) -ne $true)
    {
        log "ERROR: $inputFile is missing, SQL min/max memory will not be configured."
        return
    }

    ConfigureSQLMemory
}
catch
{
    $ex = $_.Exception | format-list | Out-String
    log "ERROR: Exception occurred `nException Message: $ex"
}

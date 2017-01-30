Param(
    [string]$scriptPath,
    [string]$SQLCOMPATIBILITYXMLFILE
)

#########################################################################
# Author: Stiven Skoklevski, CSC
# Set the SQL Compatibility based on values in XML file. 
# If the SQL instance does not exist in the XML file then no changes will be made
#########################################################################

###########################################
# Configure the SQL compatibility
###########################################
function ConfigureSQLCompatibility()
{

    # current computer
    $serverName = $env:COMPUTERNAME

    # Get the xml Data
    $xml = [xml](Get-Content $inputFile)

    $nodes = $xml.SelectNodes("//Instance")

    if (([string]::IsNullOrEmpty($nodes)))
    {
        log "No user settings to configure in: '$inputFile'"
        return
    }

    foreach ($node in $nodes) 
    {
        $DBInstanceShortName = $node.attributes['DBInstanceName'].value
        $DBList = $node.attributes['DBList'].value
        $CompatibilityMode = $node.attributes['CompatibilityMode'].value

        if (([string]::IsNullOrEmpty($DBInstanceShortName)))
        {
            log "WARNING: DBInstanceName is missing, skipping the record"
            continue
        }

        if (([string]::IsNullOrEmpty($DBList)))
        {
            log "WARNING: DBList is missing, skipping the record"
            continue
        }
        
        if (([string]::IsNullOrEmpty($CompatibilityMode)))
        {
            log "WARNING: CompatibilityMode is missing, skipping the record"
            continue
        }
        
        $vals = $DBInstanceShortName -split "\\"
        $servershortName = $vals[0]
        $dbInstance = $vals[1]
        $serverName = ([string](Get-ServerName $servershortName)).ToUpper() 
        $DBInstanceName = "$serverName\$dbInstance"

        log "INFO: Full DBInstanceName is: $DBInstanceName"

        # $instance = Get-SQLInstance -ComputerName $env:COMPUTERNAME | Where-Object {$_.FullName -eq $DBInstanceName}
        $instance = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $DBInstanceName

        if($instance.Databases.Count -le 0)
        {
            log "WARN: The instance could not be found: $DBInstanceName "
            continue
        }

        Switch ($CompatibilityMode)
        {
            "2008"
            {
                $newCompatibilityMode = [Microsoft.SqlServer.Management.Smo.CompatibilityLevel]::Version100
                $updateMsg = "Version100 (SQL 2008)"
                log "INFO: Setting Compatibility Level to $updateMsg"
            }
            "2012"
            {
                $newCompatibilityMode = [Microsoft.SqlServer.Management.Smo.CompatibilityLevel]::Version110
                $updateMsg = "Version110 (SQL 2012)"
                log "INFO: Setting Compatibility Level to $updateMsg"
            }
            default 
            {
                log "ERROR: CompatibilityMode could not be resolved. Check the SQLCompatibility.xml file."
                continue
            }
        }

        $DBList.Split(",") | foreach {

            $databaseName = $_
            $db = $instance.Databases | Where-Object {$_.Name -eq $databaseName }

            if($db -eq $null)
            {
                log "ERROR: The database was not found: $databaseName "
                continue
            }

            $db.CompatibilityLevel = $newCompatibilityMode
            $db.Alter()

            log "INFO: The database '$databaseName' compatibility level was updated to $updateMsg"
        }
    }
}

###########################################
# Main 
###########################################

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SqlEnum") | Out-Null


. .\FilesUtility.ps1
. .\UsersUtility.ps1
. .\VariableUtility.ps1
. .\PlatformUtils.ps1
. .\Get-SQLInstance.ps1

Set-Location -Path $scriptPath

if (([string]::IsNullOrEmpty($SQLCOMPATIBILITYXMLFILE)))
{
    log "ERROR: SQLCOMPATIBILITYXMLFILE is missing, users will not be configured."
    return
}

# *** configure and validate existence of input file
$inputFile = "$($scriptPath)\$($SQLCOMPATIBILITYXMLFILE)"

if ((CheckFileExists($inputFile)) -ne $true)
{
    log "ERROR: $inputFile is missing, SQL compatibility will not be configured and defaults will remain."
    return
}


ConfigureSQLCompatibility

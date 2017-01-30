Param(
    [string] $scriptPath,
    [string] $CREATEDATABASEXMLFILE
)
##################################################################
# Create a Database given the sql instance and comma delimited list of database names
##################################################################

Push-Location
Import-Module SQLPS -DisableNameChecking
Pop-Location

<#
[Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
[Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoExtended") | Out-Null
[Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo") | Out-Null
[Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoEnum") | Out-Null
#>

function PreStageDatabase()
{
    $nodes = $xmlinput.SelectNodes("//Databases/Database")
    if (([string]::IsNullOrEmpty($nodes)))
    {
        log "INFO: No databases to create in: '$inputFile'"
        return 0
    }

    foreach ($node in $nodes) 
    {
        [string]$serverList = $node.attributes['Server'].value
        [string]$instanceServerName = $node.attributes['InstanceServerName'].value
        [string]$instanceName = $node.attributes['InstanceName'].value
        [string]$databases = $node.attributes['Databases'].value
        
        #region Attributes Validation
        if([String]::IsNullOrEmpty($serverList))
        {
            log "WARNING: serverList is empty, check the configuration file"
            continue
        }

        if([String]::IsNullOrEmpty($instanceServerName))
        {
            log "WARNING: instanceServerName is empty, check the configuration file"
            continue
        }
        else
        {
            $sqlInstance = Get-ServerName ($instanceServerName).ToUpper() 
        }

        if([String]::IsNullOrEmpty($instanceName))
        {
            log "WARNING: instanceName is empty, check the configuration file"
            continue
        }
        else
        {
             $sqlInstance =  $sqlInstance + "\" + $instanceName
        }

        if([String]::IsNullOrEmpty($databases))
        {
            log "WARNING: databases is empty, check the configuration file"
            continue
        }

        #endregion

        $servers = $serverList.Split(",")
        $servers | Where-Object { 
            log "INFO: target server $_, current server $env:COMPUTERNAME"
            if((Get-ServerName ($_.Trim())).ToUpper() -eq ($env:COMPUTERNAME).ToUpper()) 
            {
                log "INFO: Databases to create on $sqlInstance are $databases"

                $srv = New-Object Microsoft.SqlServer.Management.Smo.Server($sqlInstance)
                if($srv.InstanceName -eq $null)
                {
                    log "WARN: The sql instance $sqlInstance does not exist."
                    continue
                }
        
                foreach($database in $databases.Split(","))
                {
                    try
                    {
                        $dbExists = $srv.Databases | Where-Object {$_.Name -eq $database}

                        if($dbExists -eq $null)
                        {
                            log "INFO: Creating Database: $database on $sqlInstance"
                            $db = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Database -argumentlist $srv, $database
                            $db.Create()
                            log "INFO: Created Database: $database on $sqlInstance"
                        }
                        else
                        {
                            log "INFO: Database: $database already exists on $sqlInstance"
                        }
                    }
                    catch
                    {
                        log "ERROR: $($_.Exception.Message)"
                    }
                }
            }
        }                
    }
}

############################################################################################
# Main
############################################################################################

# Load Common functions
. .\FilesUtility.ps1
. .\VariableUtility.ps1
. .\PlatformUtils.ps1
. .\LaunchProcess.ps1

Set-Location -Path $scriptPath 
. .\LoggingV2.ps1 $true $scriptPath "CreateDatabase.ps1"

try
{

    $startDate = get-date

    log "INFO: Starting creation of database"

    $inputFile = Get-VariableValue $CREATEDATABASEXMLFILE "\ConfigFiles\CreateDatabase.xml" $true
    $inputFile = ($scriptPath + $inputFile)

    if ((CheckFileExists($inputFile )) -eq $false)
    {
        log "INFO: $inputFile is missing"
        return 1
    }

    # Get the xml Data
    $xmlinput = [xml](Get-Content $inputFile)

    PreStageDatabase

    log "INFO: Finished creation of databases."
    $endDate = get-date
    $ts = New-TimeSpan -Start $startDate -End $endDate
    log "TIME: Processing Time  - $ts"

    return 0
}
catch
{
    throw "ERROR: $($_.Exception.Message)"
}
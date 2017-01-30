Param(
    [string] $scriptPath,
    [string] $sqlAliasConfigXml
)


Function MatchComputerName($computersList, $computerName)
{
	If ($computersList -like "*$computerName*") { Return $true; }
    foreach ($v in $computersList) {
      If ($v.Contains("*") -or $v.Contains("#")) {
            # wildcard processing
            foreach ($item in -split $v) {
                $item = $item -replace "#", "[\d]"
                $item = $item -replace "\*", "[\S]*"
                if ($computerName -match $item) {return $true;}
            }
        }
    }
}


# ====================================================================================
# Func: WriteLine
# Desc: Writes a nice line of dashes across the screen
# ====================================================================================
Function WriteLine
{
    log "--------------------------------------------------------------"
}

# ====================================================================================
# Func: Add-SQLAlias
# Desc: Creates a local SQL alias (like using cliconfg.exe) so the real SQL server/name doesn't get hard-coded in SharePoint
#       if local database server is being used, then use Shared Memory protocol
# From: Bill Brockbank, SharePoint MVP (billb@navantis.com)
# ====================================================================================

Function Add-SQLAlias()
{
    <#
    .Synopsis
        Add a new SQL server Alias
    .Description
        Adds a new SQL server Alias with the provided parameters.
    .Example
                Add-SQLAlias -AliasName "SharePointDB" -SQLInstance $env:COMPUTERNAME
    .Example
                Add-SQLAlias -AliasName "SharePointDB" -SQLInstance $env:COMPUTERNAME -Port '1433'
    .Parameter AliasName
        The new alias Name.
    .Parameter SQLInstance
                The SQL server Name os Instance Name
    .Parameter Port
        Port number of SQL server instance. This is an optional parameter.
    #>
    [CmdletBinding(DefaultParameterSetName="BuildPath+SetupInfo")]
    param
    (
        [Parameter(Mandatory=$false, ParameterSetName="BuildPath+SetupInfo")][ValidateNotNullOrEmpty()]
        [String]$aliasName = "SharePointDB",

        [Parameter(Mandatory=$false, ParameterSetName="BuildPath+SetupInfo")][ValidateNotNullOrEmpty()]
        [String]$SQLInstance = $env:COMPUTERNAME,

        [Parameter(Mandatory=$false, ParameterSetName="BuildPath+SetupInfo")][ValidateNotNullOrEmpty()]
        [String]$port = ""
    )

	If ((MatchComputerName $SQLInstance $env:COMPUTERNAME) -or ($SQLInstance.StartsWith($env:ComputerName +"\"))) {
		$protocol = "dbmslpcn" # Shared Memory
	}
	else {
		$protocol = "DBMSSOCN" # TCP/IP
	}

    $serverAliasConnection="$protocol,$SQLInstance"
    If ($port -ne "")
    {
         $serverAliasConnection += ",$port"
    }
    $notExist = $true
    $client = Get-Item 'HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client' -ErrorAction SilentlyContinue
    # Create the key in case it doesn't yet exist
    If (!$client) {$client = New-Item 'HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client' -Force}
    $client.GetSubKeyNames() | ForEach-Object -Process { If ( $_ -eq 'ConnectTo') { $notExist=$false }}
    If ($notExist)
    {
        $data = New-Item 'HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo'
    }
    # Add Alias
    $data = New-ItemProperty HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo -Name $aliasName -Value $serverAliasConnection -PropertyType "String" -Force -ErrorAction SilentlyContinue
}

# ====================================================================================
# Func: CheckSQLAccess
# Desc: Checks if the install account has the correct SQL database access and permissions
# By:   Sameer Dhoot (http://sharemypoint.in/about/sameerdhoot/)
# From: http://sharemypoint.in/2011/04/18/powershell-script-to-check-sql-server-connectivity-version-custering-status-user-permissions/
# Modified for use in Agilityr by Marina Krynina (CSC)
# ====================================================================================
Function CheckSQLAccess ([xml] $xmlinput)
{
    WriteLine

    $i = 0

    # Look for references to DB Servers, Aliases, etc. in the XML
    $nodes = $xmlinput.SelectNodes("//DBServers/Alias")

    ForEach ($node in $nodes)
    {
        $i++
        
        # ComponentID-InstanceID
        $aliasName = $node.GetAttribute("Name")
        log "INFO: Alias = $aliasName"

        $dbServerNode = $node.GetAttribute("DBServer")
        $dbServer = ([string](Get-ServerName $dbServerNode)).ToUpper()
        log "INFO: dbServer = $dbServer"

        $dbInstance = $dbServer + "\" + $node.GetAttribute("DBInstance")
        log "INFO: dbInstance = $dbInstance"
        
        $dbPort = $node.GetAttribute("DBPort")
        log "INFO: dbPort = $dbPort"

        #region Validation
        if ([string]::IsNullOrEmpty($dbServer))
        {
            log "WARNING: Record Number $i - dbServer is empty. Moving to the next record."
            continue
        }

        if ([string]::IsNullOrEmpty($dbInstance))
        {
            log "WARNING: Record Number $i - dbInstance is empty. Moving to the next record."
            continue
        }

        if ([string]::IsNullOrEmpty($dbPort))
        {
            log "WARNING: Record Number $i - dbPort is empty. Moving to the next record."
            continue
        }
        #endregion

        if ($node.GetAttribute("Create") -ne "true")
        {
            log "WARNING: Record Number $i - DBAlias Create flag is set to false. Moving to the next record."
            continue
        }
        else
        {
            
            log " - Creating SQL alias `"$aliasName, $dbInstance,$dbPort`"..."
            Add-SQLAlias -AliasName $aliasName -SQLInstance $dbInstance -Port $dbPort
        }

        $dbServers += @($aliasName)
    }

    $currentUser = "$env:USERDOMAIN\$env:USERNAME"
    $serverRolesToCheck = "dbcreator","securityadmin"

    ForEach ($sqlServer in ($dbServers | Select-Object -Unique))
    {
        If ($sqlServer) # Only check the SQL instance if it has a value
        {
            $objSQLConnection = New-Object System.Data.SqlClient.SqlConnection
            $objSQLCommand = New-Object System.Data.SqlClient.SqlCommand
            Try
            {
                $objSQLConnection.ConnectionString = "Server=$sqlServer;Integrated Security=SSPI;"
                log " - Testing access to SQL server/instance/alias:" $sqlServer
                log " - Trying to connect to `"$sqlServer`"..." 
                $objSQLConnection.Open() | Out-Null
                log "Success"
                $strCmdSvrDetails = "SELECT SERVERPROPERTY('productversion') as Version"
                $strCmdSvrDetails += ",SERVERPROPERTY('IsClustered') as Clustering"
                $objSQLCommand.CommandText = $strCmdSvrDetails
                $objSQLCommand.Connection = $objSQLConnection
                $objSQLDataReader = $objSQLCommand.ExecuteReader()
                If ($objSQLDataReader.Read())
                {
                    log (" - SQL Server version is: {0}" -f $objSQLDataReader.GetValue(0))
                    $SQLVersion = $objSQLDataReader.GetValue(0)
                    [int]$SQLMajorVersion,[int]$SQLMinorVersion,[int]$SQLBuild,$null = $SQLVersion -split "\."
                    log "INFO: SQLMajorVersion = $SQLMajorVersion, SQLMinorVersion = $SQLMinorVersion, SQLBuild = $SQLBuild"
                    
                    If ($objSQLDataReader.GetValue(1) -eq 1)
                    {
                        log " - This instance of SQL Server is clustered"
                    }
                    Else
                    {
                        log " - This instance of SQL Server is not clustered"
                    }
                }
                $objSQLDataReader.Close()

                ForEach($serverRole in $serverRolesToCheck)
                {
                    $objSQLCommand.CommandText = "SELECT IS_SRVROLEMEMBER('$serverRole')"
                    $objSQLCommand.Connection = $objSQLConnection
                    log " - Check if $currentUser has $serverRole server role..." 
                    $objSQLDataReader = $objSQLCommand.ExecuteReader()
                    If ($objSQLDataReader.Read() -and $objSQLDataReader.GetValue(0) -eq 1)
                    {
                        log "Pass"
                    }
                    ElseIf($objSQLDataReader.GetValue(0) -eq 0)
                    {
                        Throw "ERROR: $currentUser does not have `'$serverRole`' role!"
                    }
                    Else
                    {
                        log "Invalid Role"
                    }
                    $objSQLDataReader.Close()
                }
                $objSQLConnection.Close()
            }
            Catch
            {
                log " - Fail"
                $errText = $error[0].ToString()
                If ($errText.Contains("network-related"))
                {
                    log "ERROR: SQL Connection Error. Check server name, port, firewall."
                }
                ElseIf ($errText.Contains("Login failed"))
                {
                    log "ERROR: Not able to login. SQL Server login not created."
                }
                Else
                {
                    If (!([string]::IsNullOrEmpty($serverRole)))
                    {
                        log "ERROR: $currentUser does not have `'$serverRole`' role!"
                    }                    
                }

                log ("EXCEPTION: " + $errText)
                continue
            }
        }
    }
    WriteLine
}

################################################################################################################################################################
Set-Location -Path $scriptPath 

. .\LoggingV2.ps1 $true $scriptPath "Create-SQLAlias.ps1"
. .\FilesUtility.ps1
. .\PlatformUtils.ps1

try
{
    # Get the xml Data
    $xmlinput = [xml](Get-Content $sqlAliasConfigXml)

    CheckSQLAccess $xmlinput
}
catch
{
    log "ERROR: $($_.Exception.Message)"

    # This is done to get an error code from the scheduled task.
    Write-Output  $($_.Exception.Message) | Out-File "$scriptPath\error.txt" -Append
    throw "ERROR: $($_.Exception.Message)"
}

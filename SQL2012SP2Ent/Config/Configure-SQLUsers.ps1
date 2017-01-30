Param(
    [string]$scriptPath,
    [string]$domain,
    [string]$SQLUSERSXMLFILE     # cater for multiple DB servers eg, Shared and SharePoint
)

#########################################################################
# Author: Stiven Skoklevski, CSC
# Add users to local admins and SQL server assigning appropriate permissions/roles
#########################################################################

###########################################
# Configure accounts at the server and DB instance level
###########################################
function ConfigureSQLUsers()
{

    # current computer
    $serverName = $env:COMPUTERNAME

    # Get the xml Data
    $xml = [xml](Get-Content $inputFile)

    $nodes = $xml.SelectNodes("//*[@Type]")

    if (([string]::IsNullOrEmpty($nodes)))
    {
        log "No user settings to configure in: '$inputFile'"
        return
    }

    foreach ($node in $nodes) 
    {
        $type = $node.attributes['Type'].value
        $name = $node.attributes['Name'].value
        $addToLocalAdministrators = $node.attributes['AddToLocalAdministrators'].value
        $DBInstanceShortName = $node.attributes['DBInstanceName'].value
        $SQLRoles = $node.attributes['SQLRoles'].value
        $isDomainAccount = $node.attributes['IsDomainAccount'].value

        if ((([string]$type).ToLower() -ne "user") -and (([string]$type).ToLower() -ne "group") -and (([string]$type).ToLower() -ne "computer"))
        {
            log "WARNING: Type $type is not supported."
            continue
        }

        if (([string]::IsNullOrEmpty($Name)))
        {
            log "WARNING: Name is missing, skipping the record"
            continue
        }

        if (([string]::IsNullOrEmpty($isDomainAccount)))
        {
            log "WARNING: isDomainAccount is missing, skipping the record"
            continue
        }

        if (([string]$type).ToLower() -eq "computer")
        {
            $componentID,$instanceID = $name -Split "-"

            # Computer names always end with $
            $name = (get-Computername $componentID $instanceID) + '$'
        }
        
        # Local Admins
        if (($addToLocalAdministrators -eq $true))
        {
            log "INFO: Adding $name to $serverName Local Admins group"

            AddUserToLocalAdministrators $serverName "$domain\$name"
        }
        elseif(([string]::IsNullOrEmpty($logOnLocally)) -ne $true)
        {
            if(($logOnLocally -eq $true))
            {
                log "INFO: Configuring $name to log on locally to $serverName"

                $privilege = "SeInteractiveLogonRight"
 
                $CarbonDllPath = "$scriptPath\Install\Carbon.dll"
 
                [Reflection.Assembly]::LoadFile($CarbonDllPath)
 
                try
                {
                    [Carbon.Lsa]::GrantPrivileges( "$domain\$name" , $privilege )
                }
                catch
                {
                    $ex = $_.Exception | format-list | Out-String
                    log "ERROR: Configurig 'Log on Locally' Exception occurred `nException Message: $ex"
                    continue
                }
                log "INFO: Configured $name to log on locally to $serverName"
           }
        }

        # SQL Roles
        # computer cannot have SQL roles assigned
        if (((([string]$type).ToLower() -eq "user") -or (([string]$type).ToLower() -eq "group")) -and (!([string]::IsNullOrEmpty($DBInstanceShortName))))
        {
            if (!([string]::IsNullOrEmpty($SQLRoles)))
            {
                $vals = $DBInstanceShortName -split "\\"
                $servershortName = $vals[0]
                $dbInstance = $vals[1]
                $serverName = ([string](Get-ServerName $servershortName)).ToUpper() 
                $DBInstanceName = "$serverName\$dbInstance"

                if($isDomainAccount -eq 'TRUE')
                {
                    log "INFO: Creating domain account: Instance $DBInstanceName, User $name, SQL Roles $SQLRoles"
                    AssignSQLRoleToDomainUser "$DBInstanceName" "$domain\$name" $SQLRoles
                    log "INFO: Created domain account: Instance $DBInstanceName, User $name, SQL Roles $SQLRoles"
                }
                else
                {
                    $localSQLLoginPassword = $node.attributes['Password'].value
                    if (([string]::IsNullOrEmpty($localSQLLoginPassword)))
                    {
                        log "WARNING: localSQLLoginPassword for local account: '$name' is missing. Password will be retrieved from key/value store."
                        $lowercaseName = $name.ToLower()
                        try
                        {
                            $password = get-serviceAccountPassword -username "$lowercaseName"
                        }
                        catch
                        {
                            $ex = $_.Exception | format-list | Out-String
                            log "ERROR: $ex"
                            continue
                        }

                        log "INFO: pwd is $password"
                    }
                    else
                    {
                        $password = $localSQLLoginPassword
                    }

                    log "INFO: Creating local account: Instance $DBInstanceName, User $name, SQL Roles $SQLRoles"
                    # $login = CreateLocalSQLLogin $DBInstanceName $name $password
                    # AddSQlLoginToSQLRole $DBInstanceName $SQLRoles $login
                    AssignSQLRoleToLocalUser $DBInstanceName $name $SQLRoles $password
                    log "INFO: Created local account: Instance $DBInstanceName, User $name, SQL Roles $SQLRoles"
                }
            }
        }
    }
}

###########################################
# Main 
###########################################

. .\FilesUtility.ps1
. .\UsersUtility.ps1
. .\VariableUtility.ps1
. .\PlatformUtils.ps1

if (([string]::IsNullOrEmpty($SQLUSERSXMLFILE)))
{
    log "ERROR: SQLUSERSXMLFILE is missing, users will not be configured."
    return
}

# *** configure and validate existence of input file
$inputFile = "$scriptPath\$SQLUSERSXMLFILE"

if ((CheckFileExists( $inputFile)) -ne $true)
{
    log "ERROR: $inputFile is missing, users will not be configured."
    return
}


ConfigureSQLUsers
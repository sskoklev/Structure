Param(
    [string] $scriptPath,
    [string] $WINDOWSUSERS_XML
)

#########################################################################
# Author: Stiven Skoklevski, CSC
# Add users to local admins or local on locally permission
#########################################################################

###########################################
# Configure windows accounts
###########################################
function ConfigureWindowsUsers()
{

    # current computer
    $serverName = $env:COMPUTERNAME

    # Get the xml Data
    $xml = [xml](Get-Content $inputFile)

    $nodes = $xml.SelectNodes("//*[@Type]")

    if (([string]::IsNullOrEmpty($nodes)))
    {
        log "WARNING: No user settings to configure in: '$inputFile'"
        return
    }

    foreach ($node in $nodes) 
    {
        $type = $node.attributes['Type'].value
        $name = $node.attributes['Name'].value
        $addToLocalAdministrators = $node.attributes['AddToLocalAdministrators'].value
        $logOnLocally = $node.attributes['LogOnLocally'].value
        $DBInstanceShortName = $node.attributes['DBInstanceName'].value
        $SQLRoles = $node.attributes['SQLRoles'].value
        $isDomainAccount = $node.attributes['IsDomainAccount'].value
        $adGROUPS = $node.attributes['ADGROUPS'].value
        
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
        elseif(([string]::IsNullOrEmpty($adGROUPS)) -ne $true)
        {
            AddUserToDomainAdministrators $adGROUPS $name

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

    }
}

###########################################
# Main 
###########################################

Set-Location -Path $scriptPath 

 # Logging must be configured here. otherwise it gets lost in the nested calls
 . .\LoggingV2.ps1 $true $scriptPath "Configure-WindowsUsersV2.ps1"

 # Load Common functions
. .\FilesUtility.ps1
. .\UsersUtility.ps1
. .\VariableUtility.ps1
. .\PlatformUtils.ps1

try
{
    if (([string]::IsNullOrEmpty($WINDOWSUSERS_XML)))
    {
        log "ERROR: WINDOWSUSERS_XML variable is missing, users will not be configured."
        return
    }

    # *** configure and validate existence of input file
    $inputFile = "$scriptPath\$WINDOWSUSERS_XML"

    if ((CheckFileExists( $inputFile)) -ne $true)
    {
        log "ERROR: $inputFile file is missing, users will not be configured."
        return
    }

    $domain = get-domainshortname

    ConfigureWindowsUsers

}
catch
{
    $ex = $_.Exception | format-list | Out-String
    log "ERROR: Exception occurred `nException Message: $ex"

    exit 1
}


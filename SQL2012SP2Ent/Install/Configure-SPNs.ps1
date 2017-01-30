Param(
    [string] $scriptPath,
    [string] $SPNXMLFILE
)

#########################################################################
# Author: Stiven Skoklevski, CSC
# Register SPNs ono the server
#########################################################################

###########################################
# Configure SPNs
###########################################
function ConfigureSPNs()
{

    # Get the xml Data
    $xml = [xml](Get-Content $inputFile)

    $nodes = $xml.SelectNodes("//doc/SPN")

    if (([string]::IsNullOrEmpty($nodes)))
    {
        log "No SPNs to configure in: '$inputFile'"
        return
    }

    $domain = get-domainshortname
    $domainFQDN = get-domainname
    $svc_sql = (Get-VariableValue $SVC_SQL "svc_sql" $true)       
        
    foreach ($node in $nodes) 
    {
        $spnCommand = $node.GetAttribute('Command')
        $server = $node.GetAttribute("Server")
        $account = $node.GetAttribute('Account')
        $useFQDN = $node.GetAttribute('useFQDN')

        if (([string]::IsNullOrEmpty($spnCommand)))
        {
            log "WARN: Command is missing, skipping the record"
            continue
        }

        if (([string]::IsNullOrEmpty($server)))
        {
            log "WARN: Account is missing, skipping the record"
            continue
        }
        else
        {
            $serverName = ([string](Get-ServerName $node.GetAttribute("Server"))).ToUpper() 
        }

        if (([string]::IsNullOrEmpty($account)))
        {
            log "WARN: Server is missing, skipping the record"
            continue
        }

        if (([string]::IsNullOrEmpty($useFQDN)))
        {
            log "WARN: useFQDN is missing, skipping the record"
            continue
        }
        else
        {
            if($useFQDN -eq "TRUE")
            {
                $serverName = $serverName + "." + $domainFQDN
            }
        }

        $spnCommand1 = $spnCommand.Replace($server, $serverName)
        $spnFullCommand = "$spnCommand1 $domain\$account"

        log "INFO: Full SPN command is: $spnFullCommand"

        $User = Get-ADUser -Filter {sAMAccountName -eq $account}
        If ($User -eq $Null) 
        {
            log "WARN: User $account does not exist in AD"
            continue
        }
        Else 
        {
            log "INFO: User $account exists in AD"
            Invoke-Expression $spnFullCommand

            # without this delay registration of the SPN was not always occuring
            Start-Sleep -Seconds 30
        }
    }
}

###########################################
# Main 
###########################################

Set-Location -Path $scriptPath 

 # Logging must be configured here. otherwise it gets lost in the nested calls
 . .\LoggingV2.ps1 $true $scriptPath "Configure-SPNs.ps1"

 # Load Common functions
. .\FilesUtility.ps1
. .\UsersUtility.ps1
. .\VariableUtility.ps1
. .\PlatformUtils.ps1

try
{
    if (([string]::IsNullOrEmpty($SPNXMLFILE)))
    {
        log "ERROR: SPNXMLFILE variable is missing, users will not be configured."
        return
    }

    # *** configure and validate existence of input file
    $inputFile = "$scriptPath\$SPNXMLFILE"

    if ((CheckFileExists( $inputFile)) -ne $true)
    {
        log "ERROR: $inputFile file is missing, users will not be configured."
        return
    }

    ConfigureSPNs

    log "INFO: SPNs have been registered."
}
catch
{
    $ex = $_.Exception | format-list | Out-String
    log "ERROR: Exception occurred `nException Message: $ex"

    exit 1
}


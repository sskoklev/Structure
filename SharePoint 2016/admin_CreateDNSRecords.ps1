# IMPORTANT: The script should be executed on DNS server

# Author: Marina Krynina

###########################################
# Create DNS records
###########################################
function CreateDNSRecords([string] $inputFile)
{
    # Get the xml Data
    $xml = [xml](Get-Content $inputFile)

    $nodes = $xml.SelectNodes("//DNSRecords/Record")

    if (([string]::IsNullOrEmpty($nodes)))
    {
        log "INFO: DNS Config XML is empty"
        return
    }
  
    foreach ($node in $nodes) 
    {
        # <Record Name="portal" ZoneName="mwsaust.net" HostNameAliasToResolve="WEB-101" HostNameAlias="" RRType="CName" ></Record>

        $zoneName = $node.GetAttribute("ZoneName")
        $name = $node.GetAttribute('Name')

        $hostNameAlias = $node.GetAttribute('HostNameAlias')
        if ($hostNameAlias -eq "")
        {
            $hostName = $node.GetAttribute('HostNameAliasToResolve')
            if ($hostName -ne "")
            {
                $hostNameAlias = ((Get-ServerName ($hostName)) + "." + (get-domainname))
            }
        }


        $rrType = $node.GetAttribute('RRType')

        #region Record validation
        if (([string]::IsNullOrEmpty($zoneName)))
        {
            log "WARNING: zoneName is missing, skipping the record"
            continue
        }

        if (([string]::IsNullOrEmpty($name)))
        {
            log "WARNING: name is missing, skipping the record"
            continue
        }

        if (([string]::IsNullOrEmpty($hostNameAlias)))
        {
            log "WARNING: hostNameAlias is missing, skipping the record"
            continue
        }

        if (([string]::IsNullOrEmpty($rrType)))
        {
            log "WARNING: rrType is missing, skipping the record"
            continue
        }
        #endregion
        
        if ($rrType.ToUpper() -eq "CNAME")
        {
            try
            {
                $rec = Get-DnsServerResourceRecord -ZoneName $zoneName -Name $name -ErrorAction SilentlyContinue
                if (($rec -ne $null) -and ($rec -ne ""))
                {
                    log "INFO: DNS record $name exists in the zone $zoneName. Please check and cleanup if required. Skipping the record."
                    continue
                }
            }
            catch
            {
                
            }

            Add-DnsServerResourceRecordCName -ZoneName $zoneName -HostNameAlias $hostNameAlias -Name $name -Confirm:$false
        }
        else
        {
            throw "ERROR: INCOMPLETE CODE."
        }
    }
}

#################################################################################################
# Author: Marina Krynina
# Desc:   Create DNSrecords
#################################################################################################

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition   

. .\LoggingV3.ps1 $true $scriptPath "Create-DNSRecords.ps1"
. .\FilesUtility.ps1
. .\PlatformUtils.ps1
. .\VariableUtility.ps1


try
{
    # *** configuration input file
    $dns_config_xml = (Get-VariableValue $DNS_CONFIG_XML "ConfigFiles\SP2016-DNSRecords-Sandpit.xml" $true)    
    $inputFile = "$scriptPath\$dns_config_xml"

    if ((CheckFileExists( $inputFile)) -ne $true)
    {
        log "WARNING: Config $inputFile file is missing, DNS Records will not be created."
        return
    }
    
    CreateDNSRecords $inputFile
    
}
catch
{
    throw "ERROR: $($_.Exception.Message)"
}

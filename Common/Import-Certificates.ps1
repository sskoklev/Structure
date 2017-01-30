Param(
    [string] $scriptPath
)

###########################################
# Import Certificates
###########################################
function ImportCertificates()
{

    $domain = get-domainshortname
    $domainFull = get-domainname
    $currentServer = ([string]$env:COMPUTERNAME).ToUpper()
   
    # Get the xml Data
    $xml = [xml](Get-Content $inputFile)

    $nodes = $xml.SelectNodes("//SSLCertificates/Certificate")

    if (([string]::IsNullOrEmpty($nodes)))
    {
        log "No certificates to import in: '$inputFile'"
        return
    }

    foreach ($node in $nodes) 
    {
        $server = $node.GetAttribute("Server")
        $certFile = $node.GetAttribute('FileLocation')
        $password = $node.GetAttribute('Password')
        $friendlyName = $node.GetAttribute('FriendlyName')
        $store = $node.GetAttribute('Store')

        $bindTo = $node.GetAttribute('BindTo')

        if (([string]::IsNullOrEmpty($server)))
        {
            log "WARNING: server is missing, skipping the record"
            continue
        }
        else
        {
            $serverName = ([string](Get-ServerName $node.GetAttribute("Server"))).ToUpper() 
        }

        if (([string]::IsNullOrEmpty($certFile)))
        {
            log "WARNING: certFile is missing, skipping the record"
            continue
        }

        # MK: TODO this will change when we get commrcial certificates
        if (([string]::IsNullOrEmpty($password)))
        {
            log "WARNING: password is missing. Trying admin password."

            $user = (Get-VariableValue $ADMIN "agilitydeploy" $true)
            $adminPwd = get-serviceAccountPassword -username $user
            $secPwd = ConvertTo-SecureString -String $adminPwd -Force –AsPlainText
        }
        else
        {
            $secPwd = ConvertTo-SecureString -String $password -Force –AsPlainText
        }

        if (([string]::IsNullOrEmpty($friendlyName)))
        {
            log "WARNING: friendlyName is missing, skipping the record"
            continue
        }

        if (([string]::IsNullOrEmpty($store)))
        {
            log "WARNING: store is missing, skipping the record"
            continue
        }

        if ($currentServer.Contains($serverName))
        {
            $stores = $store.split(";")
            foreach($st in $stores)
            {
                log "INFO: importing $certFile with the firendly name of $friendlyname into $st"

                try
                {
                    $cert = ImportPfxCertificate ($scriptPath+$certFile) $secPwd $st
                    $cert.FriendlyName = $friendlyName
                }
                catch
                {
                    log "EXCEPTION OCCURRED: $($_.Exception.Message). Skipping to the next record."
                    continue
                }
                
                if (!([string]::IsNullOrEmpty($bindTo)))
                {
                    Start-Sleep 3
                    # IIS works only with the certificates from the personal store
                    $personalStore = "cert:\LocalMachine\My"
                    if ($st -eq $personalStore)
                    {
                        Add-SSLBinding $bindTo $personalStore $friendlyName
                    }
                }
            }
        }
    }
}

#################################################################################################
# Author: Marina Krynina
# Desc:   
#################################################################################################

Set-Location -Path $scriptPath 

. .\LoggingV2.ps1 $true $scriptPath "Import-Certificates.ps1"
. .\FilesUtility.ps1
. .\SSLManagementUtility.ps1
. .\PlatformUtils.ps1
. .\VariableUtility.ps1


try
{
    # this is a variable to force hardcoded defaults. It is useful for testing outside of Agility
    $useHardcodedDefaults = $false

    # *** configuration input file
    $certs_xml = (Get-VariableValue $CERTS_XML "ProductDependent.xml" $useHardcodedDefaults)    
    $inputFile = "$scriptPath\$certs_xml"

    if ((CheckFileExists( $inputFile)) -ne $true)
    {
        log "WARNING: Config $inputFile file is missing, certificates will not be imported. Assumed the certificates will be imported manually."
        return
    }
    
    ImportCertificates
    
}
catch
{
    throw "ERROR: $($_.Exception.Message)"
}

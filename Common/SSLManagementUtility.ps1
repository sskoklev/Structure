# ===================================================================================
# Author: Marina Krynina, CSC
# Func: GenerateSelfSignedCertificate
# Desc: Generates self-signed certificate
# ===================================================================================
Function GenerateSelfSignedCertificate ([string] $certcn, [string] $certStore) 
{       
    #Check if the certificate name was used before
    $thumbprint = (Get-ChildItem -Path $certStore -DNSName $certcn).Thumbprint


    if ($thumbprint.Length -gt 0)
    {
        log "INFO: Certificate for DNS $certcn already exists. Thumbprint = $thumbprint"
    }
    else
    {
        $thumbprint = New-SelfSignedCertificate -DnsName $certcn -CertStoreLocation cert:\LocalMachine\My |ForEach-Object{ $_.Thumbprint}
        log "INFO: Certificate for DNS $certcn has been created. Thumbprint = $thumbprint"
    }

    #If generated successfully
    if (($thumbprint -ne $null) -and ($thumbprint.Length -gt 0) )
    {
        return $thumbprint
    }
    else
    {
        throw "ERROR: Failed to create self-signed certificate for DNS $certcn"
    }
 }

# ===================================================================================
# Author: Marina Krynina, CSC
# Func: ExportCertificate
# Desc: Exports Certificate With or Without a Private Key.
# ===================================================================================
Function ExportCertificate ([string]$certStore, [string] $thumbprint, [string]$certFile, [System.Security.SecureString]$securePwd, [bool]$pkFlag) 
{
        
    #Check if the certificate exists
    $cert = Get-ChildItem -Path $certStore | where {$_.Thumbprint -eq $thumbprint}

    if ($cert -eq $null)
    {
        throw "ERROR: certificate $thumbprint does not exist in $certStore"
    }

    if ($pkFlag -eq $true)
    {
        if ($securePwd.Length -eq 0)
        {
            throw "ERROR: secure password is empty string"
        }

        log "INFO: Exporting Certificate with private key into $certFile"
        Export-PfxCertificate -FilePath $certFile -Cert "$certStore\$thumbprint" -Password $securePwd
    }
    else
    {
        log "INFO: Exporting Certificate without private key into $certFile"
        Get-Item -Path "$certStore\$thumbprint" | Export-Certificate -Type CERT -FilePath $certFile  -Verbose 
    }


    if ((ifFileExists( $certFile)) -ne $true)
    {
        throw "ERROR: Failed to export Certificate $certFile."
    }
    else
    {
        log "INFO: Successfully Exported Certificate into $certFile"
    }
 }

# ===================================================================================
# Author: Marina Krynina, CSC
# Func: ImportPfxCertificate
# Desc: 
# ===================================================================================
Function ImportPfxCertificate ([string] $certFile, [System.Security.SecureString] $securePwd, [string] $certStore)
{
    if ((ifFileExists( $certFile)) -ne $true)
    {
        throw "ERROR: $certFile does not exist"
    }

    if ($securePwd.Length -eq 0)
    {
        throw "ERROR: secure password is empty string"
    }

    log "INFO: Importing Certificate $certFile to $certStore"
    $cert = Import-PfxCertificate -FilePath $certFile -Password $securePwd -CertStoreLocation $certStore

    return $cert
}

# ===================================================================================
# Author: Marina Krynina, CSC
# Func: Add-IISBinding
# Desc: port 443, protocol https, no host header, ssl flag 1
# ===================================================================================
function Add-IISBinding ([string]$siteName, [string]$dns, [string]$certStore)
{
    Import-Module WebAdministration;
    New-WebBinding -Name $siteName -Port 443 -Protocol https -HostHeader "" -SslFlags 1

    $cert = (Get-ChildItem -Path $certStore -DNSName $dns)
    if ($cert -eq $null)
    {
        throw "ERROR: certificate for $dns does not exist in $certStore"
    }

    $cert | New-Item IIS:SslBindings\0.0.0.0!443!$dns -Force
    log "INFO: added IIS binding for $siteName"
}

function Get-CertByFriendlyName([string]$certStore, [string]$friendlyName)
{
    $cert = Get-ChildItem -Path $certStore | where-object {$_.FriendlyName -eq $friendlyName}
    return $cert
}

function Add-SSLBinding ([string]$siteName, [string]$certStore, [string]$friendlyName)
{
    Import-Module WebAdministration;
    New-WebBinding -Name $siteName -Port 443 -Protocol https -HostHeader "" -SslFlags 0

    $cert = Get-CertByFriendlyName $certStore $friendlyName
    if ($cert -eq $null)
    {
        throw "ERROR: certificate with the name $friendlyName does not exist in $certStore. Site $siteName cannot be bound."
    }

    $cert | New-Item IIS:SslBindings\0.0.0.0!443 -Force
    log "INFO: added IIS binding for $siteName. Certificate $friendlyName"
}

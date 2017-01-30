# ***********************************************************************************************************************
# Author: marina Krynina, CSC
# Desc: Generates a self-signed certificate. This script isexecuted manually on a server. 
# ***********************************************************************************************************************
function Generate-SelfSignedCertificate([string] $dns, [string] $certStore, [string] $certFile, [string] $password, [bool] $pkFlag)
{
    log "INFO: Creating and exporting a certificate with the following parameters:"
    log "INFO: DNS = $dns"
    log "INFO: Certificate Store = $certStore"
    log "INFO: Certificate name and location = $certFile"
    log "INFO: Password = $password"
    log "INFO: Private Key Flag = $pkFlag"

    $secPwd = ConvertTo-SecureString -String $password -Force –AsPlainText
    $thumbprint = (GenerateSelfSignedCertificate $dns $certStore)

    ExportCertificate $certStore $thumbprint $certFile $secPwd $pkFlag
}


# ***********************************************************************************************************************
# Author: Marina Krynina, CSC
# ***********************************************************************************************************************
. .\LoggingV2.ps1 $true $scriptPath "Generate-SelfSignedCertificate.ps1"
. .\FilesUtility.ps1
. .\SSLManagementUtility.ps1
. .\PlatformUtils.ps1
. .\VariableUtility.ps1

try
{
    $user = "agilitydeploy"
    $password = get-serviceAccountPassword -username $user
    $certStore = "cert:\LocalMachine\My"

    # ***********************************************************************************************************************
    # Wildcard certificate. Used on SharePoint 2013 and WAC servers
    $dns = "*.demo3.local"
    $certfriendlyname = “MWS2 Wildcard”
    
    Generate-SelfSignedCertificate $dns $certStore ".\SSLCertificates\Wildcard.pfx" $password $true

    $cert = (Get-ChildItem -Path $certStore -DNSName $dns)
    $cert.FriendlyName = $certfriendlyname

    # ***********************************************************************************************************************
    # Office Web Apps certificate. Used on SharePoint 2013 and WAC servers
    $dns = "OfficeApps.demo3.local"
    $certfriendlyname = “MWS2 OfficeApps”

    Generate-SelfSignedCertificate $dns $certStore ".\SSLCertificates\OfficeApps.pfx" $password $true

    $cert = (Get-ChildItem -Path $certStore -DNSName $dns)
    $cert.FriendlyName = $certfriendlyname
    # ***********************************************************************************************************************

}
catch
{
    throw "ERROR: $($_.Exception.Message)"
}



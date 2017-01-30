# ===================================================================================
# Author: Marina Krynina, CSC
# Desc: Deletes Certificate from a store
# ===================================================================================
Function DeleteCertificateByFriendlyName ([string]$certStore, [string] $friendlyName) 
{
    $certs = Get-ChildItem $certStore | where { $_.FriendlyName –eq $friendlyName }

    foreach ($cert in $certs) {
        $store = Get-Item $cert.PSParentPath
        $store.Open('ReadWrite')
        $store.Remove($cert)
        $store.Close()
    }
}


# use certlm.msc to view the certificates
$certFriendlyName = "MWS2R2 Wildcard"
DeleteCertificateByFriendlyName "cert:\LocalMachine\My" $certFriendlyName
DeleteCertificateByFriendlyName "Cert:\LocalMachine\Root" $certFriendlyName

$certFriendlyName = "MWS2R2 OfficeApps"
DeleteCertificateByFriendlyName "cert:\LocalMachine\My" $certFriendlyName
DeleteCertificateByFriendlyName "Cert:\LocalMachine\Root" $certFriendlyName

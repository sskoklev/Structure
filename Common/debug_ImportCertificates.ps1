# Script: Import SSL certificates
# Author: Marina Krynina
#################################################################################################
try
{
    write-host "INFO: Start Import-Certificates"

    # get current script location
    $scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
    
    # Agility Variables - set default   
    $ADMIN = "agilitydeploy"
    $CERTS_XML = "ConfigFiles\AW-Certificates.xml"
       
    . .\Import-Certificates.ps1 $scriptPath

    exit 0
}
catch
{
    $ex = $_.Exception | format-list | Out-String
    write-host "ERROR: Exception occurred `nException Message: $ex"

    exit 1
}
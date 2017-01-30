Param(
    [string] $scriptPath,
    [string] $testFolder
)

############################################################################################
# Author: Marina Krynina
# Desc: Server side Unit testing - Common  
# Updates:
#          Added windows features - Stiven
############################################################################################
# Main   
############################################################################################
# \USER_PROFILE
#        \TestResults\SERVER-PRODUCT.html

Set-Location -Path $scriptPath 

try 
{
    $product = "Common"

    . .\LoggingV2.ps1 $true $scriptPath "unitTest-Server-$product.ps1"
    . "$scriptPath\$testFolder\HTMLGenerator.ps1"
    . "$scriptPath\$testFolder\UnitTest-Common-Utilities.ps1"


    log "INFO: Script path $scriptPath\$testFolder"

    $dtStart =  get-date

    log "INFO: about to call domainInfo"
    $frag1 = Build-HTML-Fragment (get-DomainInfo) LIST "<h2>Domain Info</h2>"
    
    log "INFO: about to call serverInfo"
    $frag2 = Build-HTML-Fragment (get-ServerInfo) LIST "<h2>Server Info</h2>" 

    log "INFO: about to call volumesInfo"
    $frag3 = Build-HTML-Fragment (get-VolumesInfo) TABLE "<h2>Volumes Info</h2>"
    
    log "INFO: about to call windows features"
    $frag4 = Build-HTML-Fragment (get-WindowsFeatures) TABLE "<h2>Windows Features</h2>" 
    
    log "INFO: about to call get-Service"
    $frag5 = Build-HTML-Fragment (get-Services @()) TABLE "<h2>Services</h2>" 

    log "INFO: about to call get-LocalGroupsAndUsers"
    $frag6 = Build-HTML-Fragment (get-LocalGroupsAndUsers) TABLE "<h2>Local Groups And Users</h2>" 

    log "INFO: about to call certificatesInfo"
    $frag7 = Build-HTML-Fragment (get-CertificatesInfo) TABLE "<h2>Certificates Info</h2>" 
    
    $content = "$frag1 $frag2 $frag3 $frag4 $frag5 $frag6 $frag7"

    Build-HTML-UnitTestResults $content $dtStart $product "$scriptPath\$testFolder"

    exit 0
}
catch
{
    log "ERROR: $($_.Exception.Message)"

    # This is done to get an error code from the scheduled task.
    Write-Output  $($_.Exception.Message) | Out-File "$scriptPath\error.txt" -Append
    exit -1
}
Param(
    [string] $scriptPath,
    [string] $testFolder
)

############################################################################################
# Author: Marina Krynina
# Desc: Server side Unit testing - Common  IIS
############################################################################################

############################################################################################
# Main
############################################################################################
# \USER_PROFILE
#        \TestResults\SERVER-PRODUCT.html

Set-Location -Path $scriptPath 

try 
{
    Import-Module Webadministration

    $product = "CommonIIS"

    . .\LoggingV2.ps1 $true $scriptPath "unitTest-Server-$product.ps1"
    . "$scriptPath\$testFolder\HTMLGenerator.ps1"
    . "$scriptPath\$testFolder\UnitTest-Common-Utilities.ps1"

    log "INFO: Script path $scriptPath\$testFolder"

    $dtStart =  get-date

    log "INFO: about to call get-WebBindings"
    $frag1 = Build-HTML-Fragment (get-WebBindings) TABLE "<h2>Web Bindings</h2>"

    log "INFO: about to call get-IISSites"
    $frag2 = Build-HTML-Fragment (get-IISSites) TABLE "<h2>Sites from IIS:\Sites</h2>"

    log "INFO: about to call get-SSLBindings"
    $frag3 = Build-HTML-Fragment (get-SSLBindings) TABLE "<h2>SSL bindings from IIS:\SslBindings\0.0.0.0!443</h2>"

    $content = "$frag1 $frag2 $frag3"

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
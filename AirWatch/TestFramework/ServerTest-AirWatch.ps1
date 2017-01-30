Param(
    [string] $scriptPath,
    [string] $testFolder
)

############################################################################################
# Author: Marina Krynina
# Desc: Server side testing - AirWatch  
############################################################################################

function get-InstalledPrograms()
{ 
    try
    {
        $objects = @()
        $objects += (Get-WmiObject -class win32_product | Select Name, Version  | Sort-Object Name)
    }
    catch
    {
        $objects = get-Exception $($_.Exception.Message)
    }
    finally
    {
        Write-Output $objects
    }
}

function get-NetFrameworkRelease()
{
    try
    {
        $objects = @()
        $objects += (Get-ChildItem 'Microsoft.Powershell.Core\Registry::HKLM\SOFTWARE\Microsoft\NET Framework Setup\NDP' -recurse |
                            get-ItemProperty -name Version, Release -EA 0 |
                            Where {$_.PSChildName -match '^(?!S)\p{L}'} |
                            Select PSChildName, Version, Release)
    }
    catch
    {
        $objects = get-Exception $($_.Exception.Message)
    }
    finally
    {
        Write-Output $objects
    }
}

function get-StatusOfWindowsfeature([string] $name)
{
    try
    {
        $objects = @()
        $objects += (Get-WindowsFeature -Name $name | Select Name, DisplayName, Installed, InstallState, Path)
    }
    catch
    {
        $objects = get-Exception $($_.Exception.Message)
    }
    finally
    {
        Write-Output $objects
    }

}

############################################################################################
# Main
############################################################################################
# \USER_PROFILE
#        \TestResults\SERVER-PRODUCT.html

log "INFO: Script path $scriptPath"
Set-Location -Path $scriptPath 

try
{
    $product = "AirWatch"
    . .\LoggingV3.ps1 $true $scriptPath "unitTest-Server-$product.ps1"
    . "$scriptPath\$testFolder\HTMLGenerator.ps1"
    . "$scriptPath\$testFolder\UnitTest-Common-Utilities.ps1"

   
    $dtStart =  get-date

    # TODO: in the future when have time, validate agains this XML
    $validationXML = "\ConfigFiles\AirWatchValidation.xml"

    log "INFO: about to call NetFrameworkRelease"
    $installedPrograms = Build-HTML-Fragment (get-InstalledPrograms) TABLE "<h2>Installed Programs</h2>"
    
    log "INFO: about to call InstalledPrograms"
    $netVersion = Build-HTML-Fragment (get-NetFrameworkRelease) TABLE "<h2>.NET Framework Version and Release</h2>"

    log "INFO: about to call StatusOfWindowsfeature"
    $featureName = "*DAV*" #WebDAV should not be installed!
    $featureStatus = Build-HTML-Fragment (get-StatusOfWindowsfeature "*DAV*") TABLE "<h2>Status of Windows Feature WebDAV</h2>"
    

    $content = "$installedPrograms`
                $netVersion`
                $featureStatus"

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
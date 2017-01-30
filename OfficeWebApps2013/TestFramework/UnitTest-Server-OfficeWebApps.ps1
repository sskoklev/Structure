Param(
    [string] $scriptPath,
    [string] $testFolder
)

############################################################################################
# Author: Marina Krynina
# Desc: Server side Unit testing - Office Web Apps  
############################################################################################
function get-FunctionTemplate()
{
    try
    {
        $objects = @()
        $object = New-Object -TypeName PSObject
        $object | Add-Member -Name 'CHANGEME' -MemberType Noteproperty -Value 'CHANGEME'
        $objects += $object
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
function get-Farm()
{ 
    try
    {
        $objects = @()
        $objects += Get-OfficeWebAppsFarm
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

function get-Machine()
{ 
    try
    {
        $objects = @()
        $objects += Get-OfficeWebAppsMachine
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

function get-Host()
{ 
    try
    {
        $objects = @()
        $objects += Get-OfficeWebAppsHost
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

function get-ProductInfo()
{ 
    try
    {
        $objects = @()

        $content = Get-Content C:\ProgramData\Microsoft\OfficeWebApps\Data\local\OfficeVersion.inc
        foreach ($line in $content)
        {
            if(!([string]::IsNullOrEmpty($line)))
            {
            $object = New-Object -TypeName PSObject
            $object | Add-Member -Name 'Product Info' -MemberType Noteproperty -Value $line
            $objects += $object
            }
        }
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
    $product = "OffieWebApps"

    . .\LoggingV2.ps1 $true $scriptPath "unitTest-Server-$product.ps1"
    . "$scriptPath\$testFolder\HTMLGenerator.ps1"
    . "$scriptPath\$testFolder\UnitTest-Common-Utilities.ps1"

   
    # TODO: The hardcoded values should come from somewhere

    $dtStart =  get-date

    log "INFO: about to call ProductInfo"
    $productInfo = Build-HTML-Fragment (get-ProductInfo) LIST "<h2>Product Information</h2>"
    
    log "INFO: about to call OfficeWebAppsFarm"
    $farmInfo = Build-HTML-Fragment (get-Farm) LIST "<h2>Farm Information</h2>" 

    log "INFO: about to call get-Machine"
    $machineInfo = Build-HTML-Fragment (get-Machine) TABLE "<h2>Machine Information</h2>"

    # log "INFO: about to call get-Host"
    # $hostInfo = Build-HTML-Fragment (get-Host) TABLE "<h2>Host Information</h2>"

    $content = "$productInfo `
                $farmInfo `
                $machineInfo"

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
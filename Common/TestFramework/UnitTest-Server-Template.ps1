Param(
    [string] $scriptPath,
    [string] $testFolder
)

############################################################################################
# Author: Marina Krynina
# Desc: Server side Unit testing - Template and Sample  
############################################################################################

# Step 1 - Create Test function
function get-ObjectToTest-Template
{  
    try
    {
        $objects = @()
        $object = New-Object -TypeName PSObject
        
        ###############################################################
        # START
        # Get you object here
        $myObject = $env:CommonProgramFiles
        # Populate properties
        $object | Add-Member -Name 'CHANGE ME Name 1' -MemberType Noteproperty -Value "CHANGE ME $myObject"
        $object | Add-Member -Name 'CHANGE ME Name 2' -MemberType Noteproperty -Value "CHANGE ME $myObject"
        $object | Add-Member -Name 'CHANGE ME Name 3' -MemberType Noteproperty -Value "CHANGE ME $myObject"
        # END
        ###############################################################
        
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
# Main
############################################################################################
# \USER_PROFILE
#        \TestResults\SERVER-PRODUCT.html

Set-Location -Path $scriptPath 

try
{
    # Step 1 - Change product value
    $product = "Template"

    . "$scriptPath\$testFolder\HTMLGenerator.ps1"
    . .\LoggingV2.ps1 $true $scriptPath "unitTest-Server-$product.ps1"
    
    log "INFO: Script path $scriptPath"

    $dtStart =  get-date
    
    # Step 2 - Call the test functions here
    log "INFO: about to call get-ObjectToTest-Template"
    $frag1 = Build-HTML-Fragment (get-ObjectToTest-Template) TABLE "<h2>CHANGE ME heading</h2>" 
    $frag2 = Build-HTML-Fragment (get-ObjectToTest-Template) LIST "<h2>CHANGE ME heading</h2>" 

    # Step 3 - Populate content
    $content = "$frag1 $frag2"

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
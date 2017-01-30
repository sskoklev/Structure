############################################################################################
# Author: Marina Krynina
# Desc: Set of common unit test functions 
############################################################################################

############################################################################################
# Author: Marina Krynina
# Desc: Sample
############################################################################################
function get-ObjectToCheckSample
{
    $objects = @()

    # Get your object here
    # $myObject = $env:USERANAME

    $object = New-Object -TypeName PSObject
    $object | Add-Member -Name 'Name' -MemberType Noteproperty -Value "SampeObject"  # $myObject.Name
    $object | Add-Member -Name 'State' -MemberType Noteproperty -Value "ImplementMe" # $myObject.State
    $objects += $object

    Write-Output $objects
}


############################################################################################
# Author: Marina Krynina
# Desc: Creates HTML fragment
############################################################################################
Function CreateHtmlFragment 
{
    [CmdletBinding()]
    [OutputType([string])]
    Param (      
        [Parameter(Mandatory=$true, ValueFromPipeline=$false, Position=0)]
        [string] $outputAs,
   
        [Parameter(Mandatory=$true, ValueFromPipeline=$false, Position=1)]
        [string] $preContent,
   
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=2)]
        [PSObject[]]$InputObject

    )

    begin { $psObj = @() }
    process { $psObj += $InputObject }
    end
    {
        if ($psObj -ne $null -and $psObj.Length -ne 0)
        {
       
            if($outputAs.ToUpper() -eq "LIST")
            {
                $psObjAsString = $psObj | ConvertTo-Html -As LIST -Fragment -PreContent $preContent | Out-String
            }

            if($outputAs.ToUpper() -eq "TABLE")
            {
                $psObjAsString = $psObj | ConvertTo-Html -As TABLE -Fragment -PreContent $preContent | Out-String
            }

            Write-Output $psObjAsString
         }
         else
         {
            Write-Output ""
         }
    }
}



function get-CommonHeader($dtStart, $dtEnd)
{
    [CmdletBinding()]
    [OutputType([PSObject[]])]
    $objects = @()

    $object = New-Object -TypeName PSObject
    $object | Add-Member -Name 'Product' -MemberType Noteproperty -Value $product
    $object | Add-Member -Name 'Server' -MemberType Noteproperty -Value $env:COMPUTERNAME
    $object | Add-Member -Name 'Current User' -MemberType Noteproperty -Value "$env:USERDOMAIN\$env:USERNAME"
    $object | Add-Member -Name 'Start Time' -MemberType Noteproperty -Value $dtStart
    $object | Add-Member -Name 'Finish Time' -MemberType Noteproperty -Value $dtEnd

    $objects += $object
    Write-Output $objects
}

function get-TestFolder([string]$testFolder)
{
    if(!(Test-Path -Path $testFolder))
    {
        $NewLogFolder = New-Item -Path $testFolder -Type Directory
        If ($NewLogFolder -ne $Null) {
            log "Created Test folder $testFolder"
        }
        else
        {
            throw "ERROR: Could not create specified test folder"
        }
    }

    Write-Output $testFolder
}

########################################################################################################
$scriptPath = "c:\users\mkrynina"
#$scriptPath = $env:USERPROFILE

Set-Location -Path $scriptPath 

. .\LoggingV2.ps1 $true $scriptPath "unitTest_Server_Product.ps1"

try
{
    $product = "Sample"
    $domain = $env:USERDOMAIN
    $domainFull = $env:USERDNSDOMAIN
   
    # Results HTML file name
    $resultFile = (get-TestFolder "$scriptPath\Test") + "\UnitTest-$env:COMPUTERNAME-$product.html"

    #################################################################################################
    $dtStart =  get-date -Format "dd-MMM-yyyy HH:mm:ss"

    ################
    log "INFO: about to call domainInfo"
    $frag1 = get-ObjectToCheckSample | CreateHtmlFragment TABLE "<h2>Sample Info</h2><p>1</p>"
    $frag2 = get-ObjectToCheckSample | CreateHtmlFragment LIST "<h2>Sample Info</h2><p>2</p>"
    $frag3 = get-ObjectToCheckSample | CreateHtmlFragment TABLE "<h2>Sample Info</h2><p>3</p>"
    $frag4 = get-ObjectToCheckSample | CreateHtmlFragment TABLE "<h2>Sample Info</h2><p>4</p>"
    

    ################
    $frag1 = WrapperFragment (get-ObjectToCheckSample) TABLE "heading"
    $frag2 = WrapperFragment (get-ObjectToCheckSample) TABLE "heading"

    $content = "$frag1 $frag2"

    Build-HTMLResult $content

    ################

    $dtEnd =  get-date -Format "dd-MMM-yyyy HH:mm:ss"
    
    log "INFO: about to call get-CommonHeader"
    $preContent = get-CommonHeader $dtStart $dtEnd | CreateHtmlFragment LIST "<h1>Unit Testing Results on server $env:COMPUTERNAME</h1>"
    #################################################################################################
  
$head = @'

<style>

body { background-color:#dddddd;

       font-family:Tahoma;

       font-size:10pt; }

td, th { border:0.5px solid grey;

         border-collapse:collapse; }

th { color:white;

     background-color:black; }

table, tr, td, th { padding: 2px; margin: 0px }

table { margin-left:50px; }

</style>

'@
 
    ConvertTo-HTML -head $head -PostContent $content -PreContent $preContent | Out-file $resultFile
    
    # This willopen the results file automatically. Helpfull to use in debug mode
    Invoke-Item $resultFile
}
catch
{
    log "ERROR: $($_.Exception.Message)"
    throw "ERROR: $($_.Exception.Message)"
}

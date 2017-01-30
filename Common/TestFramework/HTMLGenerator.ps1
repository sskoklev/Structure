############################################################################################
# Author: Marina Krynina
# Desc: Set functions to support creating of a HTML file. 
#       Currently used in Unit Testing Framework 
# Updates:
# - Stiven Skoklevski: load dll for non-web servers
############################################################################################

# load dll for non-web servers
Add-Type -Path 'TestFramework\System.Web.dll'

function get-Exception($exception)
{
    $objects = @()
    $object = New-Object PSObject
    $object | Add-Member -MemberType NoteProperty -Name "Exception Occurred" -Value $exception
    $objects += $object

    Write-Output $objects
}

# AddColor $status "online" "green"
function AddColor([string]$varToColor, [string]$valueToCompare, [string]$colorToAdd)
{
    $coloredStr = $varToColor

    if($varToColor.ToUpper() -eq $valueToCompare.ToUpper())
    {
        $coloredStr = '<font color="' + $colorToAdd + '">' + $varToColor + '</font>'
    }

    Write-Output ($coloredStr)
}

function HtmlFormat ([string]$strToFormat)
{           
    if ($strToFormat.Contains("&lt;") -or $strToFormat.Contains("&gt;") -or $strToFormat.Contains("&quot;"))
    {
        $strToFormat = [System.Web.HttpUtility]::HtmlDecode($strToFormat)
    }

    Write-Output $strToFormat
}

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
        [AllowNull()]
        [PSObject[]]$InputObject

    )

    begin { $psObj = @() }
    process 
    { 
        if ($InputObject -ne $null -and $InputObject.Length -ne 0)
        {
            $psObj += $InputObject 
        }
    }
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

            Write-Output (HtmlFormat $psObjAsString )
         }
         else
         {
            Write-Output ""
         }
    }
}

function get-CommonHeader($product, $dtStart, $dtEnd)
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

function get-Folder([string]$folder)
{
    if(!(Test-Path -Path $folder))
    {
        $NewLogFolder = New-Item -Path $folder -Type Directory
        If ($NewLogFolder -ne $Null) {
            log "Created folder $folder"
        }
        else
        {
            throw "ERROR: Could not create specified folder"
        }
    }

    Write-Output $folder
}

function get-ResultsFileFullName([string]$testFolder, [string]$product)
{
    $date = get-date -Format "yyyyMMdd-HHmmss"

    if (!([string]::IsNullOrEmpty($product)))
    {
        $resultsFile = (get-Folder $testFolder) + "\$env:COMPUTERNAME-$product.$date.html"
    }
    else
    {
        $resultsFile = (get-Folder $testFolder) + "\$env:COMPUTERNAME.$date.html"
    }

    Write-Output $resultsFile
}

function Build-HTML-Fragment
{
   Param (      
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0)]
        [AllowNull()]
        [PSObject[]]$InputObject,

        [Parameter(Mandatory=$true, ValueFromPipeline=$false, Position=1)]
        [string] $outputAs = "LIST",
   
        [Parameter(Mandatory=$true, ValueFromPipeline=$false, Position=2)]
        [string] $preContent = "<h2>Default Heading</h2>"
   
    )

    begin { $psObj = @() }
    process 
    { 
        if ($InputObject -ne $null -and $InputObject.Length -ne 0)
        {
            $psObj += $InputObject 
        }
    }
    end
    {
        if ($psObj -ne $null -and $psObj.Length -ne 0)
        {
            $uniqueID = [guid]::NewGuid()
            # wrap heading in anchors to make collapsible
            $preContentCollapsible = "<label class='collapse' for='$uniqueID'>$preContent</label>
                           <input id='$uniqueID' type='checkbox'><div>"

            $psObjAsString = $psObj | CreateHtmlFragment $outputAs $preContentCollapsible
   
            Write-Output "$psObjAsString </div>"
         }
         else
         {
            Write-Output ""
         }
    }
}

function Build-HTML-UnitTestResults
{
   Param (      
        [Parameter(Mandatory=$true, ValueFromPipeline=$false, Position=0)]
        [string] $content = "<p>No content was provided</p>",
        [Parameter(Mandatory=$false, ValueFromPipeline=$false, Position=1)]
        [DateTime] $start = (get-date),
        [Parameter(Mandatory=$false, ValueFromPipeline=$false, Position=2)]
        [string] $product = "",
        [Parameter(Mandatory=$false, Position=3)]
        [string]$testFrameworkLocation = ""
    )


    $resultFile = get-ResultsFileFullName "$testFrameworkLocation\Results" $product

    $dtStart =  $start.ToString("dd-MMM-yyyy HH:mm:ss")
    $dtEnd =  get-date -Format "dd-MMM-yyyy HH:mm:ss"

    $preContent = get-CommonHeader $product $dtStart $dtEnd | CreateHtmlFragment LIST "<h1>Unit Testing Results on server $env:COMPUTERNAME</h1>"
  
    $head = @'


<style>

body { background-color:#dddddd;

       font-family:Calibri,Tahoma;

       font-size:10pt; }

td, th { border:0.5px solid grey;

         border-collapse:collapse; }

th { color:white;

     background-color:black; }

table, tr, td, th { padding: 2px; margin: 0px }

table { margin-left:50px; }

.collapse{
  color:Blue;
  text-decoration: underline;
  display:block;
}
.collapse + input{
  display:none;
}
.collapse + input + *{
  display:none;
}
.collapse+ input:checked + *{
  display:block;
}

</style>

'@
 
    ConvertTo-HTML -head $head -PostContent $content -PreContent $preContent | Out-file $resultFile
    
    # This willopen the results file automatically. Helpfull to use in debug mode
    Invoke-Item $resultFile

}

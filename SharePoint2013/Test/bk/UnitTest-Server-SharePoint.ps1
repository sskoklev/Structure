Param(
    [string] $scriptPath
)

############################################################################################
# Author: Marina Krynina
# Desc: Server side Unit testing - SharePoint  
############################################################################################
function get-ObjectToCheckSample
{  
    # Get your object here:
    # Get an object as is
    $myObject1 = Get-SPServiceApplication 

    # Get an object with selected properties
    $myObject2 = Get-SPServiceApplication | Select DisplayName,Id,Status, ApplicationPool

    # scenario 1: Ouput Object as is
    $objects = @()
    $objects += $object
    
    # scenario 2: Ouput Object with specific properties 
    $objects = @()       
    $object = New-Object -TypeName PSObject
    $object | Add-Member -Name 'Name' -MemberType Noteproperty -Value $myObject.DisplayName
    $object | Add-Member -Name 'State' -MemberType Noteproperty -Value $myObject.DisplayName
    $objects += $object


    Write-Output $objects
}

Function Get-RegistryKeyPropertiesAndValues
{
  <#
   .Synopsis
    This function accepts a registry path and returns all reg key properties and values
   .Description
    This function returns registry key properies and values.
   .Example
    Get-RegistryKeyPropertiesAndValues -path 'HKCU:\Volatile Environment'
    Returns all of the registry property values under the \volatile environment key
   .Parameter path
    The path to the registry key
   .Notes
    NAME:  Get-RegistryKeyPropertiesAndValues
    AUTHOR: ed wilson, msft
    LASTEDIT: 05/09/2012 15:18:41
    KEYWORDS: Operating System, Registry, Scripting Techniques, Getting Started
    HSG: 5-11-12
   .Link
     Http://www.ScriptingGuys.com/blog
 #Requires -Version 2.0
 #>
 Param(
  [Parameter(Mandatory=$true)]
  [string]$path)
 Get-Item $path |
    Select-Object -ExpandProperty property |
    ForEach-Object {
        New-Object psobject -Property @{"property"=$_;
        "Value" = (Get-ItemProperty -Path $path -Name $_).$_}}
} #end function Get-RegistryKeyPropertiesAndValues

function get-HTTPResponse([string]$url)
{
    $HTTP_Request = [System.Net.WebRequest]::Create($url)
    $HTTP_Response = $HTTP_Request.GetResponse()
    $HTTP_Status = [int]$HTTP_Response.StatusCode

    If ($HTTP_Status -eq 200) { 
        $rv = "SUCCESS: HTTP Status = $HTTP_Status" 
    }
    Else {
        $rv = "FAILURE: HTTP Status = $HTTP_Status"
    }

    $HTTP_Response.Close()

    Write-Output $HTTP_Status
}

function get-HTTPResponse1($url, $username, $password)
{
    $webRequest = [System.Net.WebRequest]::Create($url)
    $webRequest.Credentials = New-Object System.Net.NetworkCredential -ArgumentList $username, $password 


    $webRequest.PreAuthenticate = $true
    $webRequest.Headers.Add("AUTHORIZATION", "Basic");

    [System.Net.WebResponse] $resp = $webRequest.GetResponse();
    $rs = $resp.GetResponseStream();
    [System.IO.StreamReader] $sr = New-Object System.IO.StreamReader -argumentList $rs;
    [string] $results = $sr.ReadToEnd();

    return $results
}

function hitSharePointUrl($url)
{
    $webclient = new-object System.Net.WebClient
    $webClient.UseDefaultCredentials = $true
    $webpage = $webclient.DownloadString("$url/Pages/Default.aspx")
}

function get-InstallLocation()
{
    [xml]$xmlinput = (Get-Content $installFile)
    $installLocation =  $xmlinput.Configuration.INSTALLLOCATION.Value
    if (Test-Path  ($installLocation))
    {
        $ifExist = "PASSED"
    }
    else
    {
        $ifExist = "FAILED"
    }
  
    $objects = @()
    $object = New-Object -TypeName PSObject
    $object | Add-Member -Name 'Folder Exist' -MemberType Noteproperty -Value $ifExist
    $object | Add-Member -Name 'Install Location' -MemberType Noteproperty -Value $installLocation
    $objects += $object

    Write-Output $objects
}

function get-ProductInfo()
{
    $products = @{
    "35466B1A-B17B-4DFB-A703-F74E2A1F5F5E" = "Project Server 2013"; 
    "BC7BAF08-4D97-462C-8411-341052402E71" = "Project Server 2013 Preview"; 
    "C5D855EE-F32B-4A1C-97A8-F0A28CE02F9C" = "SharePoint Server 2013";
    "CBF97833-C73A-4BAF-9ED3-D47B3CFF51BE" = "SharePoint Server 2013 Preview";
    "B7D84C2B-0754-49E4-B7BE-7EE321DCE0A9" = "SharePoint Server 2013 Enterprise";
    "298A586A-E3C1-42F0-AFE0-4BCFDC2E7CD0" = "SharePoint Server 2013 Enterprise Preview";
    "D6B57A0D-AE69-4A3E-B031-1F993EE52EDC" = "Microsoft Office Online";
    "9FF54EBC-8C12-47D7-854F-3865D4BE8118" = "SharePoint Foundation 2013"
    }

    $registryPath = "HKLM:software\Microsoft\Shared Tools\Web Server Extensions\$((Get-SPFarm).BuildVersion.Major).0\WSS\InstalledProducts"
        
    $prods = Get-RegistryKeyPropertiesAndValues -path $registryPath
    $objects = @()

    foreach($prod in $prods)
    {
        $object = New-Object -TypeName PSObject
        $object | Add-Member -Name 'Product' -MemberType Noteproperty -Value $products.Get_Item($prod.value)
        $object | Add-Member -Name 'SKU ID' -MemberType Noteproperty -Value $prod.value
        $object | Add-Member -Name 'Version' -MemberType Noteproperty -Value $((Get-SPFarm).BuildVersion)
        $objects += $object        
    }
        
    Write-Output $objects 
}

function get-FarmAccount()
{
    $objects = @()
    
    $farmAcct = (Get-SPFarm).DefaultServiceAccount.Name | out-string

    $object = New-Object -TypeName PSObject
    $object | Add-Member -Name 'Farm System Account' -MemberType Noteproperty -Value $farmAcct

    $objects += $object

    Write-Output $objects 
}

function get-ManagedAccounts()
{
    $managedAccts = Get-SPManagedAccount

    $objects = @()
    foreach($ma in $managedAccts)
    {
        $object = New-Object -TypeName PSObject
        $object | Add-Member -Name 'Managed Account' -MemberType Noteproperty -Value $ma.UserName
        $object | Add-Member -Name 'Password Expiration' -MemberType Noteproperty -Value $ma.PasswordExpiration
        $objects += $object
    }

    Write-Output $objects 
}

function get-SuperUsers()
{

    $objects = @()
    Get-SPWebApplication | 
    Foreach-object {$object = New-Object -TypeName PSObject; 
                    $object | Add-Member -Name 'Web App' -MemberType Noteproperty -Value $($_.url);
                    $object | Add-Member -Name 'Super user' -MemberType Noteproperty -Value $($_.properties[“portalsuperuseraccount”]);
                    $object | Add-Member -Name 'Super reader' -MemberType Noteproperty -Value $($_.properties[“portalsuperreaderaccount”]);
                    $objects += $object}

    Write-Output $objects 
}

function get-FarmTopology()
{ 
    $objects = @()
    $servers = Get-SPServer | Select DisplayName, Role
    $objects += $servers

    Write-Output $objects 
}

function get-Services ($services)
{
    [CmdletBinding()]
    [OutputType([PSObject[]])]

    $objects = @()

    if ($services -ne $null -and $services.Length -gt 0)
    {
        foreach($s in $services)
        {
            $svc = ([string]$s).Trim().ToUpper()
            $service = Get-WmiObject win32_service | Where-Object {(([string]$_.name).ToUpper() -eq $svc) -or (([string]$_.displayname).ToUpper() -eq $svc)}

            $object = New-Object -TypeName PSObject
            $object | Add-Member -Name 'Given Name' -MemberType Noteproperty -Value $svc

            if ($service -eq $null)
            {
                $object | Add-Member -Name 'Service Display Name' -MemberType Noteproperty -Value ""
                $object | Add-Member -Name 'Service Name' -MemberType Noteproperty -Value ""
                $object | Add-Member -Name 'State' -MemberType Noteproperty -Value "Does Not Exist"
            }
            else
            {
                $object | Add-Member -Name 'Service Display Name' -MemberType Noteproperty -Value $service.displayname
                $object | Add-Member -Name 'Service Name' -MemberType Noteproperty -Value $service.name
                $object | Add-Member -Name 'State' -MemberType Noteproperty -Value $service.State
            }

            $objects += $object
        }
    }

    Write-Output $objects
}

function get-SpServiceAppsInfo()
{
    $objects = @()
    $serviceApps = Get-SPServiceApplication | Select DisplayName,ApplicationVersion,@{Name='ApplicationPool';Expression={$_.ApplicationPool.Name}},Name,Id,Status
    $objects += $serviceApps

    Write-Output $objects  
}

function get-SpServicesOnServer()
{
    $objects = @()
    $serviceInstances = Get-SPServiceInstance -Server $env:COMPUTERNAME | Select DisplayName,TypeName,Status,Id
    $objects += $serviceInstances

    Write-Output $objects 
}

function get-SpDatabases()
{
    $objects = @()
    $dbs = Get-SPdatabase | Select Name, Type
    $objects += $dbs

    Write-Output $objects 
}

function discover-OfficeWebApps()
{
    $urls = @()

    $url = "https://OfficeApps.demo3.local/hosting/discovery"
    
    $objects = @()
    $siteStatus = get-HTTPResponse $url

    $object = New-Object -TypeName PSObject
    $object | Add-Member -Name 'Display name' -MemberType Noteproperty -Value "OfficeWebApps"
    $object | Add-Member -Name 'URL' -MemberType Noteproperty -Value $url
    $object | Add-Member -Name 'Status' -MemberType Noteproperty -Value $siteStatus
    $objects += $object

    Write-Output $objects 
}

function get-SpWebApps()
{
    $webApps = Get-SPWebApplication -IncludeCentralAdministration
    $objects = @()

    foreach($wa in $webApps)
    {
        try
        {
            $siteStatus = get-HTTPResponse1 $wa.Url "demo3\aglitydeploy" "M3sh@dmin!"
        }
        catch
        {
            $siteStatus = $($_.Exception.Message)
        }

        $object = New-Object -TypeName PSObject
        $object | Add-Member -Name 'Display name' -MemberType Noteproperty -Value $wa.DisplayName
        $object | Add-Member -Name 'URL' -MemberType Noteproperty -Value $wa.Url
        $object | Add-Member -Name 'Status' -MemberType Noteproperty -Value $siteStatus
        $objects += $object
    }

    Write-Output $objects
}

function get-SpSiteCollections()
{
    $siteCols = Get-SPsite
    $objects = @()

    foreach($sc in $siteCols)
    {
        try
        {
            #$siteStatus = get-HTTPResponse $sc.Url "demo3\aglitydeploy" "M3sh@dmin!"
            $siteStatus = hitSharePointUrl $sc.Url
        }
        catch
        {
            $siteStatus = $($_.Exception.Message)
        }

        $object = New-Object -TypeName PSObject
        $object | Add-Member -Name 'URL' -MemberType Noteproperty -Value $sc.Url
        $object | Add-Member -Name 'Status' -MemberType Noteproperty -Value $siteStatus
        $objects += $object
    }

    Write-Output $objects 
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
    . .\HTMLGenerator.ps1

    $product = "SharePoint"
    . .\LoggingV2.ps1 $true $scriptPath "unitTest-Server-$product.ps1"

    Add-PsSnapin Microsoft.SharePoint.PowerShell -ErrorAction Stop | Out-Null
    
    $installFile = "$scriptPath\InstallMedia\SilentConfig.xml"
    $configFile = "$scriptPath\Config\MWS2_SPFarm.xml"
    $cerificatesFile = "$scriptPath\Config\SharePointCertificates.xml"

    $dtStart =  get-date

    log "INFO: about to call InstallLocation"
    $frag1 = Build-HTML-Fragment (get-InstallLocation) LIST "<h2>Install Location</h2>"
    
    log "INFO: about to call ProductInfo"
    $frag2 = Build-HTML-Fragment (get-ProductInfo) LIST "<h2>product Information</h2>" 

    log "INFO: about to call get-Service"
    $frag3 = Build-HTML-Fragment (get-Services @("SPuserCodeV4", "SPTimerV4", "SpTraceV4")) TABLE "<h2>Default SharePoint Services</h2>" 

    log "INFO: about to call FarmAccount"
    $frag4 = Build-HTML-Fragment (get-FarmAccount) LIST "<h2>System Accounts</h2><h3>Farm account</h3>"
    
    log "INFO: about to call ManagedAccounts"
    $frag5 = Build-HTML-Fragment (get-ManagedAccounts) LIST "<h3>Managed Accounts</h3>" 
    
    log "INFO: about to call SuperUsers"
    $frag6 = Build-HTML-Fragment (get-SuperUsers) TABLE "<h3>Super Users</h3>" 
    
    log "INFO: about to call get-FarmTopology"
    $frag7 = Build-HTML-Fragment (get-FarmTopology) TABLE "<h2>SharePoint Farm Topology</h2>"

    log "INFO: about to call get-SpServiceAppsInfo"
    $frag8 = Build-HTML-Fragment (get-SpServiceAppsInfo) TABLE "<h2>Service Applications</h2>"

    log "INFO: about to call get-SpServicesOnServer"
    $frag9 = Build-HTML-Fragment (get-SpServicesOnServer) TABLE "<h2>Services On Server</h2>"

    log "INFO: about to call get-SpDatabases"
    $frag10 = Build-HTML-Fragment (get-SpDatabases) TABLE "<h2>SharePoint Databases</h2>"

    log "INFO: about to call discover-OfficeWebApps"
    $frag11 = Build-HTML-Fragment (discover-OfficeWebApps) TABLE "<h2>Office Web Apps</h2>"

    log "INFO: about to call get-SpWebApps"
    $frag12 = Build-HTML-Fragment (get-SpWebApps) TABLE "<h2>SharePoint Web Applications</h2>"

    log "INFO: about to call get-SpSiteCollections"
    $frag13 = Build-HTML-Fragment (get-SpSiteCollections) TABLE "<h2>SharePoint Site Collections</h2>"

    $content = "$frag1 $frag2 $frag3 $frag4 $frag5 $frag6 $frag7 $frag8 $frag9 $frag10 $frag11 $frag12 $frag13"

    Build-HTML-UnitTestResults $content $dtStart $product $scriptPath

    exit 0
}
catch
{
    log "ERROR: $($_.Exception.Message)"

    # This is done to get an error code from the scheduled task.
    Write-Output  $($_.Exception.Message) | Out-File "$scriptPath\error.txt" -Append
    exit -1
}
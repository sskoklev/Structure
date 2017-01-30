Param(
    [string] $scriptPath,
    [string] $testFolder
)

############################################################################################
# Author: Marina Krynina
# Desc: Server side Unit testing - SharePoint  
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

function ColorIt([string]$varToColor)
{
    $goodValues = @("ONLINE", "ACTIVE", "UP", "PASSED", "RUNNING", "TRUE", "SUCCESS", "RUNNING", "STARTED")
    $badValues = @("DISABLED", "DOWN", "FAILED", "STOPPED", "INACTIVE", "FALSE", "UNKNOWN", "PROVISIONING", "STARTING", "STOPPING")

    $coloredStr = $varToColor.ToUpper()

    if ($goodValues.Contains($coloredStr))
    {
        $colorToAdd = "green"
    }
    elseif ($badValues.Contains($coloredStr))
    {
        $colorToAdd = "red"
    }
    else
    {
        $colorToAdd = ""
        $coloredStr = $varToColor
    }
    
    if ($colorToAdd -ne "")
    {
        $coloredStr = AddColor $varToColor $varToColor $colorToAdd
    }

    Write-Output ($coloredStr)
}

function if-LogonLocallyPermissionForUser ([string] $user)
{
    $sidstr = $null
    try {
	    $ntprincipal = new-object System.Security.Principal.NTAccount "$user"
	    $sid = $ntprincipal.Translate([System.Security.Principal.SecurityIdentifier])
	    $sidstr = $sid.Value.ToString()
    } catch {
	    $sidstr = $null
    }

    if(!([string]::IsNullOrEmpty($sidstr) ))
    {   
        $tmp = [System.IO.Path]::GetTempFileName()

        secedit.exe /export /cfg "$($tmp)" | out-null

        $c = Get-Content -Path $tmp 

        $currentSetting = ""

        foreach($s in $c) 
        {
	        if( $s -like "SeInteractiveLogonRight*") 
            {
		        $x = $s.split("=",[System.StringSplitOptions]::RemoveEmptyEntries)
		        $currentSetting = $x[1].Trim()
	        }
        }

        if( $currentSetting -like "*$($sidstr)*" ) 
        {
            Write-Output $true
        }
        else
        {
            Write-Output $false
        }
    }
    else
    {
	    Write-Output $false
    }
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

function access-SharePointPage([string]$url, [string]$urlSuffix)
{
    $webclient = new-object System.Net.WebClient
    $webClient.UseDefaultCredentials = $true
    #$pageUrl = "$url/_layouts/settings.aspx"
    $pageUrl = "$url/$urlSuffix"
    $webpage = $webclient.DownloadString($pageUrl)
    if (!([string]::IsNullOrEmpty($webpage)))
    {
        Write-Output $true
    }
    else
    {
        Write-Output $false
    }
}

Function MatchComputerName($computersList, $computerName)
{
	If ($computersList -like "*$computerName*") { Return $true; }
    foreach ($v in $computersList) {
      If ($v.Contains("*") -or $v.Contains("#")) {
            # wildcard processing
            foreach ($item in -split $v) {
                $item = $item -replace "#", "[\d]"
                $item = $item -replace "\*", "[\S]*"
                if ($computerName -match $item) {return $true;}
            }
        }
    }
}

Function ShouldIProvision([System.Xml.XmlNode] $node)
{
    If (!$node) {Return $false} # In case the node doesn't exist in the XML file
    # Allow for comma- or space-delimited list of server names in Provision or Start attribute
    If ($node.GetAttribute("Provision")) {$v = $node.GetAttribute("Provision").Replace(","," ")}
    ElseIf ($node.GetAttribute("Start")) {$v = $node.GetAttribute("Start").Replace(","," ")}
    ElseIf ($node.GetAttribute("Install")) {$v = $node.GetAttribute("Install").Replace(","," ")}
    If ($v -eq $true) { Return $true; }
    Return MatchComputerName $v $env:COMPUTERNAME
}

function matchServiceByName([string]$givenName, [string]$displayName, [string]$actualName)
{
    if (($actualName.ToUpper() -eq $givenName.ToUpper()) -or ($displayName.ToUpper() -eq $givenName.ToUpper()))
    {
        Write-Output $true
    }
    else
    {
        Write-Output $false
    }
}

function get-SpServiceIdentity($typename)
{
    $identity = Get-SPServiceInstance -Server $env:COMPUTERNAME | Where-Object {$_.Typename -like $typename} | select -expand service | % { if ( $_.ProcessIdentity -and $_.ProcessIdentity.GetType() -eq "String") { $_.ProcessIdentity } elseif ( $_.ProcessIdentity ) { $_.ProcessIdentity.UserName }}
    Write-Output $identity
}


function get-spServiceByName([string]$spServiceName)
{
    Write-Output (Get-SPServiceInstance | Where-Object {$_.TypeName -like $spServiceName})
}
############################################################################################
function get-InstallLocation()
{
    [xml]$xmlinput = (Get-Content $installFile)
    $installLocation =  $xmlinput.Configuration.INSTALLLOCATION.Value
    if (Test-Path  ($installLocation))
    {
        $ifExist = AddColor "PASSED" "passed" "green"
    }
    else
    {
        $ifExist = AddColor "FAILED" "failed" "red"
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

    try
    {
        $objects = @()

        $registryPath = "HKLM:software\Microsoft\Shared Tools\Web Server Extensions\$((Get-SPFarm).BuildVersion.Major).0\WSS\InstalledProducts"
        
        $prods = Get-RegistryKeyPropertiesAndValues -path $registryPath

        foreach($prod in $prods)
        {
            $object = New-Object -TypeName PSObject
            $object | Add-Member -Name 'Product' -MemberType Noteproperty -Value $products.Get_Item($prod.value)
            $object | Add-Member -Name 'SKU ID' -MemberType Noteproperty -Value $prod.value
            $object | Add-Member -Name 'Version' -MemberType Noteproperty -Value $((Get-SPFarm).BuildVersion)
            $objects += $object        
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

function get-FarmTopology()
{ 
    try
    {
        $objects = @()
        $servers = Get-SPServer | Select DisplayName, @{Name='Role';Expression={if ($_.Role -eq "Invalid"){""}else{$_.Role}}} -ErrorAction Stop
        $objects += $servers
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

function get-winServices ($arrayServices)
{
    try
    {
        $objects = @()
        if ($arrayServices -ne $null -and $arrayServices.Length -gt 0)
        {
            foreach($s in $arrayServices)
            {
                $svc = ([string]$s).Trim().ToUpper()
                $service = Get-WmiObject win32_service | Where-Object {matchServiceByName $svc $_.displayname $_.name} | Select Name, StartName, StartMode, State
                $objects += $service
            }
        }
        else
        {
            # all services?
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

function get-SpServicesOnServer
{
    try
    {
        $objects = @()

        $serviceInstances = Get-SPServiceInstance  | Select TypeName | Sort-Object TypeName | group {$_.TypeName}
        $servers = Get-SPServer | Where-Object { $_.Role -ne ‘Invalid’ }

        foreach($si in $serviceInstances)
        {
            write-host $si.name
            $object = New-Object -TypeName PSObject
            $object | Add-Member -Name 'Service' -MemberType Noteproperty -Value $si.Name

            foreach($server in $servers)
            {
               $sinsOnS =  Get-SPServiceInstance -Server $server | where-object {$_.TypeName -eq $si.name}
               foreach($sin in $sinsOnS )
               { 
                    $object | Add-Member -Name $server.Address -MemberType Noteproperty -Value (AddColor $sin.status "online" "green") 
               }
            }

            $objects += $object
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

function get-SpDatabases()
{
    try
    {
        $objects = @()
        $dbs = Get-SPdatabase | Select Name, Type
        $objects += $dbs
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

function discover-OfficeWebApps($url)
{
    try
    {
        $objects = @()
        $siteStatus = get-HTTPResponse $url

        $object = New-Object -TypeName PSObject
        $object | Add-Member -Name 'Display name' -MemberType Noteproperty -Value "OfficeWebApps"
        $object | Add-Member -Name 'URL' -MemberType Noteproperty -Value $url
        $object | Add-Member -Name 'Status' -MemberType Noteproperty -Value (ColorIt $siteStatus)
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

function get-ManagedPaths
{
    Get-SPManagedPath
}

function get-SpWebAppDetails($wa)
{
    try
    {        
        $object = New-Object -TypeName PSObject
        $object | Add-Member -Name 'Display name' -MemberType Noteproperty -Value $wa.DisplayName
        $object | Add-Member -Name 'URL' -MemberType Noteproperty -Value $wa.Url
        $mpaths = Get-SPManagedPath -WebApplication $wa.Url
        $str = ""
        foreach($mpath in $mpaths)
        {
            if ($mpath.Name -eq "") {$name = "(root)"} else {$name = $mpath.Name}
            $str += ("Name = " + $name + ", Type = " + $mpath.Type +  "<br>")
        }

        $object | Add-Member -Name 'Managed Path' -MemberType Noteproperty -Value $str

        # people picker
        $pps = $wa.PeoplePickerSettings.SearchActiveDirectoryDomains
        $str = ""
        foreach($pp in $pps)
        {
            $str += ("DomainName = " + $pp.DomainName + ", LoginName = " + $pp.LoginName + "<br>")
        }
        $object | Add-Member -Name 'People Picker' -MemberType Noteproperty -Value $str

        #AAM
        $str = ""
        $aams = $wa.AlternateUrls
        foreach($aam in $aams)
        {
            $str += ("IncomingUrl = " + $aam.IncomingUrl + "<br>Zone = " + $aam.Zone + "<br>PublicUrl = " + $aam.PublicUrl +  "<br>----------------<br>")
        }
        $object | Add-Member -Name 'Alternate URLs' -MemberType Noteproperty -Value $str

        $dbs = Get-SPContentDatabase -webapplication $wa.Url
        $strDb = ""
        $strDbCount = ""
        $strDbServer = ""
        foreach($db in $dbs)
        {
            $strDb += ($db.Name + "<br>")
            $strDbCount += ([string]$db.CurrentSiteCount + "<br>")
            $strDbServer += ($db.Server + "<br>")
            $strDbConn += ($db.DatabaseConnectionString + "<br>")
        }

        $object | Add-Member -Name 'Content DB' -MemberType Noteproperty -Value $strDb
        $object | Add-Member -Name 'Current Site Count' -MemberType Noteproperty -Value $strDbCount
        $object | Add-Member -Name 'Server' -MemberType Noteproperty -Value $strDbServer
        $object | Add-Member -Name 'Connection String' -MemberType Noteproperty -Value $strDbConn
    }
    catch
    {
        $objects = get-Exception $($_.Exception.Message)
    }
    finally
    {
        Write-Output $object

    }
}

function get-SpWebAppSettings($wa)
{
    try
    {        
        $object = New-Object -TypeName PSObject
        $Zone=[Microsoft.SharePoint.Administration.SPUrlZone]::Default 
        $prov = $wa.IisSettings[$Zone]
        
        $object | Add-Member -Name 'Web App' -MemberType Noteproperty -Value $wa.DisplayName
        $object | Add-Member -Name 'Allow Anonymous' -MemberType Noteproperty -Value $prov.AllowAnonymous
        $object | Add-Member -Name 'Use Claims Authentication' -MemberType Noteproperty -Value $prov.UseClaimsAuthentication
        $object | Add-Member -Name 'Windows Integrated Authentication' -MemberType Noteproperty -Value $prov.UseWindowsIntegratedAuthentication
        $object | Add-Member -Name 'Kerberos Disabled' -MemberType Noteproperty -Value $prov.DisableKerberos
        $object | Add-Member -Name 'Enable Client Integration' -MemberType Noteproperty -Value $prov.EnableClientIntegration
        $object | Add-Member -Name 'Require User Remote Interfaces Permissions' -MemberType Noteproperty -Value $prov.ClientObjectModelRequiresUseRemoteAPIsPermission

        $object | Add-Member -Name 'Max File Upload Size ' -MemberType Noteproperty -Value $wa.MaximumFileSize                       
        $object | Add-Member -Name 'Usage Cookie Status' -MemberType Noteproperty -Value $wa.AllowAnalyticsCookieForAnonymousUsers 
        $object | Add-Member -Name 'List View Lookup Threshold ' -MemberType Noteproperty -Value $wa.MaxQueryLookupFields                  
        $object | Add-Member -Name 'Enable SharePoint Designer' -MemberType Noteproperty -Value $wa.AllowDesigner                         
        $object | Add-Member -Name 'Enable detaching Pages from Site Collections' -MemberType Noteproperty -Value $wa.AllowRevertFromTemplate               
        $object | Add-Member -Name 'Enable Customizing Master Pages and Layout Pages' -MemberType Noteproperty -Value $wa.AllowMasterPageEditing                
        $object | Add-Member -Name 'Enabling Managing of the Web Site URL Structure' -MemberType Noteproperty -Value $wa.ShowURLStructure                      

        $object | Add-Member -Name 'Self Site Creation' -MemberType NoteProperty -Value $wa.SelfServiceSiteCreationEnabled 

        $object | Add-Member -Name 'Outbound Mail Service Instance Status' -MemberType Noteproperty -Value (ColorIt $wa.OutboundMailServiceInstance.Status)
        $object | Add-Member -Name 'Outbound Mail Sender Address' -MemberType Noteproperty -Value $wa.OutboundMailSenderAddress
        $object | Add-Member -Name 'Outbound Mail Reply To Address' -MemberType Noteproperty -Value $wa.OutboundMailReplyToAddress

        # $object | Add-Member -Name 'Virtual Directory' -MemberType Noteproperty -Value $prov.Path
    }
    catch
    {
        $objects = get-Exception $($_.Exception.Message)
    }
    finally
    {
        Write-Output $object

    }
}


function get-SpWebApps()
{
    $exceptionPlaceholder = ""
    $sectionHeading = "<h2>Content Web Application(s)</h2>"

    try
    {
        $webApps = Get-SPWebApplication
        $objects = @()
        $settings = @()

        foreach($wa in $webApps)
        {
            
            $objects += get-SpWebAppDetails($wa)
            $strObjects = Build-HTML-Fragment ($objects) TABLE ("<li><h3>Web Applications</h3></li>" )

            $settings += get-SpWebAppSettings($wa)
            $strSettings = Build-HTML-Fragment ($settings) LIST "<li><h3>Settings</h3></li>" 

        }
    }
    catch
    {
        $objects = get-Exception $($_.Exception.Message)
        $exceptionPlaceholder = Build-HTML-Fragment ($objects) TABLE "<b><font color='red'>Exception occurred</font></b>"
    }
    finally
    {
        Write-Output "$sectionHeading $exceptionPlaceholder <ul>$strObjects $strSettings</ul>"
    }
}


function get-SpSiteCollections()
{
    try
    {
        $webApps = Get-SPWebApplication

        foreach($wa in $webApps)
        {
            $siteCols = Get-SPSite | % {$_.RootWeb.SiteAdministrators} | select @{name='Url';expr={$_.ParentWeb.Url}}, LoginName, Email
            $objects = @()

            foreach($sc in $siteCols)
            {
                $object = New-Object -TypeName PSObject
                $object | Add-Member -Name 'URL' -MemberType Noteproperty -Value $sc.Url
                $object | Add-Member -Name 'Site Administrators' -MemberType Noteproperty -Value $sc.LoginName

                try
                {
                    $siteStatus =  access-SharePointPage $sc.Url "/_layouts/15/settings.aspx"
                    if ($siteStatus)
                    {
                        $object | Add-Member -Name 'Test Access' -MemberType Noteproperty -Value (ColorIt "Success")
                    }
                }
                catch
                {
                    $object | Add-Member -Name 'Test Access' -MemberType Noteproperty -Value (ColorIt "Failed")
                    $object | Add-Member -Name 'Access Exception' -MemberType Noteproperty -Value $($_.Exception.Message)
                }

                $dbs = Get-SPContentDatabase -site $sc.Url
                $strDb = ""
                foreach($db in $dbs)
                {
                    $strDb += ($db.Name + "<br>")
                }

                $object | Add-Member -Name 'Content DB' -MemberType Noteproperty -Value $strDb

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

function get-CentralAdminInfo()
{
    try
    {
        $ca = Get-SPWebApplication -includecentraladministration | where {$_.IsAdministrationWebApplication}
        $db = Get-SPContentDatabase –WebApplication $ca.url

        $objects = @()
        $object = New-Object -TypeName PSObject
        $object | Add-Member -Name 'Display name' -MemberType Noteproperty -Value $ca.DisplayName
        $object | Add-Member -Name 'DB Name' -MemberType Noteproperty -Value $db.Name
        $object | Add-Member -Name 'DB Server' -MemberType Noteproperty -Value $db.Server
        $object | Add-Member -Name 'URL' -MemberType Noteproperty -Value $ca.Url
        if (access-SharePointPage $ca.Url "default.aspx")
        {
            $object | Add-Member -Name 'Accessing URL' -MemberType Noteproperty -Value (ColorIt "Passed")
        }
        else
        {
            $object | Add-Member -Name 'Accessing URL' -MemberType Noteproperty -Value (ColorIt "Failed")
        }

        # By default CS is created in the default zone
        $Zone=[Microsoft.SharePoint.Administration.SPUrlZone]::Default 
        $prov = $ca.IisSettings[$Zone]
        
        $object | Add-Member -Name 'Authentication Mode' -MemberType Noteproperty -Value $prov.AuthenticationMode
        $object | Add-Member -Name 'Allow Anonymous' -MemberType Noteproperty -Value $prov.AllowAnonymous
        $object | Add-Member -Name 'Windows Integrated Authentication' -MemberType Noteproperty -Value $prov.UseWindowsIntegratedAuthentication
        $object | Add-Member -Name 'Kerberos Disabled' -MemberType Noteproperty -Value $prov.DisableKerberos
        $object | Add-Member -Name 'Enable Client Integration' -MemberType Noteproperty -Value $prov.EnableClientIntegration
        $object | Add-Member -Name 'Require User Remote Interfaces Permissions' -MemberType Noteproperty -Value $prov.ClientObjectModelRequiresUseRemoteAPIsPermission

        $farm = Get-SpFarm | select Name, Status
        $object | Add-Member -Name 'Farm' -MemberType Noteproperty -Value $farm.Name
        $object | Add-Member -Name 'Status' -MemberType Noteproperty -Value (ColorIt $farm.Status)

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

function get-FarmAccount()
{
    try
    {
        $objects = @()
    
        $farmAcct = (Get-SPFarm).DefaultServiceAccount.Name

        $object = New-Object -TypeName PSObject
        $object | Add-Member -Name 'Farm System Account' -MemberType Noteproperty -Value ([string]$farmAcct)
        
        $isLocalAdmin = $false
        $localAdmins = Get-LocalGroupMembers | where-object {$_."Local Group" -like "Administrators"} | select Name, Domain
        foreach ($localAdmin in $localAdmins)
        {
            $user = $localAdmin.Domain + "\" + $localAdmin.Name

            if ($user -like $farmAcct)
            {
               $isLocalAdmin = $true
            }
            else
            {
                $isLocalAdmin = $false
            }
        }

        $object | Add-Member -Name 'Is local Administrator' -MemberType Noteproperty -Value (ColorIt ([string]$isLocalAdmin))
        $object | Add-Member -Name 'Logon Locally' -MemberType Noteproperty -Value (ColorIt ([string](if-LogonLocallyPermissionForUser ([string]$farmAcct))))
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

function get-ManagedAccounts()
{
    try
    {
        $managedAccts = Get-SPManagedAccount -ErrorAction Stop

        $objects = @()
        foreach($ma in $managedAccts)
        {
            $object = New-Object -TypeName PSObject
            $object | Add-Member -Name 'Managed Account' -MemberType Noteproperty -Value $ma.UserName
            $object | Add-Member -Name 'Password Expiration' -MemberType Noteproperty -Value $ma.PasswordExpiration
            $objects += $object
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

function get-ObjectCacheAccounts()
{
    try
    {
        $objects = @()
        Get-SPWebApplication | 
        Foreach-object {$object = New-Object -TypeName PSObject; 
                        $object | Add-Member -Name 'Web App' -MemberType Noteproperty -Value $($_.url);
                        $object | Add-Member -Name 'Super user' -MemberType Noteproperty -Value $($_.properties[“portalsuperuseraccount”]);
                        $object | Add-Member -Name 'Super reader' -MemberType Noteproperty -Value $($_.properties[“portalsuperreaderaccount”]);
                        $objects += $object}
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

function get-FarmAdministrators()
{
    try
    {
        $objects = @()
        # farm admins
        $farmAdmins = Get-SPWebApplication -IncludeCentralAdministration | ? IsAdministrationWebApplication | Select -Expand Sites | ? ServerRelativeUrl -eq "/" | Get-SPWeb | Select -Expand SiteGroups | ? Name -eq "Farm Administrators" | Select -expand Users
        $objects += $farmAdmins | select UserLogin, IsSiteAdmin
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


function get-AppPoolsAccounts()
{
    try
    {
        $objects = @()

        # Service Application Pool accounts
        $svcAppPoolsAccts = Get-SPServiceApplicationPool
        $objects += $svcAppPoolsAccts | select Name, @{Name='UserName';Expression={$_.ProcessAccountName}}
        
        $webAppPoolsAccts = [Microsoft.SharePoint.Administration.SPWebService]::ContentService.ApplicationPools
        $objects += $webAppPoolsAccts | select Name, @{Name='UserName';Expression={$_.Username}}
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

function get-SpServicesAccounts()
{
    try
    {
        $objects = @()

        # Service Instance accounts
        # Get-SPServiceInstance | select -expand service | % { if ( $_.ProcessIdentity -and $_.ProcessIdentity.GetType() -eq "String") { $_.ProcessIdentity } elseif ( $_.ProcessIdentity ) { $_.ProcessIdentity.UserName }}
        $services = Get-SPServiceInstance -Server $env:COMPUTERNAME | select -expand service
        foreach($service in $services)
        {
            $procIdentity = ""
            $object = New-Object -TypeName PSObject; 
 
            $procIdentity = get-SpServiceIdentity $service.TypeName
            if (! ([string]::IsNullOrEmpty($procIdentity)))
            {
                $object | Add-Member -Name 'SharePoint Service' -MemberType Noteproperty -Value $service.TypeName
                $object | Add-Member -Name 'Windows Service' -MemberType Noteproperty -Value $service.Name
                $object | Add-Member -Name 'Process identity' -MemberType Noteproperty -Value $procIdentity
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

function get-OtherServices()
{
    try
    {
        $objects = @()
        $objects += Get-WmiObject -Query "select * from win32_service where name LIKE 'SP%v4'" | select Name, StartName, StartMode, State
        $objects += Get-WmiObject -Query "select * from win32_service where name LIKE '%14'" | select Name, StartName, StartMode, State
        $objects += Get-WmiObject -Query "select * from win32_service where name LIKE '%15'" | select Name, StartName, StartMode, State

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

function get-SearchCrawlAccount()
{
    try
    {
        $objects = @()

        # Search crawler account
        # $objects += New-Object Microsoft.Office.Server.Search.Administration.content $(Get-SPEnterpriseSearchServiceApplication) | Select DefaultGatheringAccount

        $object = New-Object -TypeName PSObject
        $object | Add-Member -Name 'CHANGEME' -MemberType Noteproperty -Value "Not Implemented"
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

function get-UserProfileSynchAccount()
{
    try
    {
        $objects = @()

        # User Profile Synchronization Service Connection. 
        #$configManager = New-Object Microsoft.Office.Server.UserProfiles.UserProfileConfigManager( $(Get-SPServiceContext http://yourSite))
        #$configManager | select -expand connectionmanager | select AccountUserName

        $object = New-Object -TypeName PSObject
        $object | Add-Member -Name 'CHANGEME' -MemberType Noteproperty -Value "Not Implemented"
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

function get-SystemAccounts()
{
    log "INFO: about to call FarmAccount"
    $acct1 = Build-HTML-Fragment (get-FarmAccount) LIST "<li><h3>Farm account</h3></li>"

    log "INFO: about to call ManagedAccounts"
    $acct2 = Build-HTML-Fragment (get-ManagedAccounts) TABLE "<li><h3>Managed Accounts</h3></li>" 

    log "INFO: about to call ObjectCacheAccounts"
    $acct3 = Build-HTML-Fragment (get-ObjectCacheAccounts) TABLE "<li><h3>Object Cache Accounts</h3></li>" 

    log "INFO: about to call FarmAdministrators"
    $acct4 = Build-HTML-Fragment (get-FarmAdministrators) TABLE "<li><h3>Farm Administrators</h3></li>" 

    log "INFO: about to call AppPoolsAccounts"
    $acct6 = Build-HTML-Fragment (get-AppPoolsAccounts) TABLE "<li><h3>Application Pools Accounts</h3></li>"    

    log "INFO: about to call SpServicesAccounts"
    $acct7 = Build-HTML-Fragment (get-SpServicesAccounts) TABLE "<li><h3>SharePoint Services Accounts</h3></li>" 

    log "INFO: about to call SearchCrawlAccount"
    $acct8 = Build-HTML-Fragment (get-SearchCrawlAccount) TABLE "<li><h3>Search Crawl Account</h3></li>" 

    log "INFO: about to call UserProfileSynchAccount"
    $acct9 = Build-HTML-Fragment (get-UserProfileSynchAccount) TABLE "<li><h3>User Profile Synch Account</h3></li>" 

    $accounts = "<h2>System Accounts</h2><ul> $acct1 $acct2 $acct3 $acct4 $acct5 $acct6 $acct7 $acct8 $acct9 </ul>"

    Write-Output $accounts
}

function get-WindowsServices()
{
    $services = @()
    log "INFO: about to call get-winServices"
    $services += get-winServices @("FIMService", "FIMSynchronizationService", "AppFabricCachingService")
    log "INFO: about to call OtherServices"
    $services += get-OtherServices

    $winS = Build-HTML-Fragment ($services) TABLE "<h2>SharePoint related windows Services</h2>" 

    Write-Output $winS
}

function get-DistributedCache([xml]$xmlinput)
{
    $exceptionPlaceholder = ""
    $sectionHeading = "<h2>Distributed Cache in Details</h2>"
    try
    {
        Use-CacheCluster
    
        # Actual results
        $objects = @()
        $svc = Get-SPServiceInstance | ? {($_.service.tostring()) -eq "SPDistributedCacheService Name=AppFabricCachingService"} | select Displayname, TypeName, Server, Status

        foreach($s in $svc)
        {
            $svcObj = New-Object -TypeName PSObject
            $svcObj | Add-Member -Name 'Display Name' -MemberType Noteproperty -Value $s.DisplayName
            $svcObj | Add-Member -Name 'Type Name' -MemberType Noteproperty -Value $s.TypeName
            $svcObj | Add-Member -Name 'Server' -MemberType Noteproperty -Value $s.Server
            $svcObj | Add-Member -Name 'Status' -MemberType Noteproperty -Value $s.Status
            $svcObj | Add-Member -Name 'Process identity' -MemberType Noteproperty -Value (get-SpServiceIdentity $s.TypeName)
            $objects += $svcObj 
        }

        # Expected results
        if (ShouldIProvision $xmlinput.Configuration.Farm.Services.DistributedCache -eq $true)
        {
            #$svcObj | Add-Member -Name 'Expected result' -MemberType Noteproperty -Value "S.b. PROVISIONED"
        }
        else
        {
            #$svcObj | Add-Member -Name 'Expected result' -MemberType Noteproperty -Value "S.NOT b. PROVISIONED"
        }

        $sectionHeading += "<p>The Distributed Cache depends on Windows Server AppFabric as a prerequisite. 
                               <br>Do not administer the AppFabric Caching Service from the Services window in Administrative Tools in Control Panel. 
                               <br>Do not use the applications in the folder named AppFabric for Windows Server on the Start menu.</p>" 
        $spSvc = Build-HTML-Fragment ($objects) TABLE "<li><h3>SharePoint service</h3></li>"
        $winSvc = Build-HTML-Fragment (get-winServices @("AppFabricCachingService")) LIST "<li><h3>Windows service(s)</h3></li>" 
    }
    catch
    {
        $objects = get-Exception $($_.Exception.Message)
        $exceptionPlaceholder = Build-HTML-Fragment ($objects) TABLE "<b><font color='red'>Exception occurred</font></b>"
    }
    finally
    {
        Write-Output "$sectionHeading $exceptionPlaceholder <ul>$spSvc $winSvc</ul>"
    }
}

function get-ServiceInstances ($saInstances)
{
    $svc = ""
    foreach($saInst in $saInstances)
    {
        $svc += ($saInst.Server.Name + ", Status = " + (ColorIt $saInst.Status) + "<br>")
    }

    Write-Output $svc
}

function get-AppPoolDetails ($appPool)
{
    $ap = ""
    if ($appPool -ne $null)
    {
        $ap += "Name = " + $appPool.Name + "<br>"
        $ap += "Status = " + (ColorIt $appPool.Status) + "<br>"
        $ap += "Identity = " + $appPool.ProcessAccountName + "<br>"
    }

    Write-Output $ap
}

function get-ServiceAppExtraInfo($sa)
{
    $strDB = ""
    $typename = $sa.TypeName

    switch -wildcard ($typename) 
    { 
        "Secure Store*" 
        {
            $db = get-SpDatabases | where-object {$_.Type -eq "Microsoft.Office.SecureStoreService.Server.SecureStoreServiceDatabase"}
            $strDB = "Database = " + $db.name
        } 
        "State Service*" 
        {
            $strDB = "Database = " + (Get-SPStateServiceDatabase).Name
        } 
        "Managed Metadata*" 
        {
            $strDB = "Database = " + $sa.Database.Name
        } 
        "App Management*" 
        {
            foreach($db in $sa.Databases)
            {
               $strDB += "Database = " + $db.Name + "<br>"
            }
            
            $strDB += ("App Domain" + (Get-SPAppDomain))
        } 
        "Security Token*" {$strDB =""} 
        "Application Discovery*" {$strDB =""} 
        "Usage and Health*" 
        {
            $strDB = "Database = " + $sa.UsageDatabase.name + "<br>"
            $strDB  += "Usage Log Folder = " + (Get-SPUsageService).UsageLogDir
        }
        "*Subscription Settings*" 
        {
            $db = get-SpDatabases | where-object {$_.Type -eq "Microsoft SharePoint Foundation Subscription Settings Database"}   
            $strDB = "Database = " + $db.name
        } 
        "Search Administration*" {$strDB =""} 
        "Work Management*" {$strDB =""} 
        "Search Service*" 
        {
            $strDB = "Crawl DB = " + $sa.CrawlStores.Name + "<br>"
            $strDB += "Links DB = " + $sa.LinksStores.Name + "<br>"
            $strDB += "Analytics DB = " + $sa.AnalyticsReportingStores.Name + "<br>"
            $strDB += "Admin DB = " + $sa.SearchAdminDatabase.Name + "<br>"

        } 
        "Distributed*" {$strDB =""} 
        "User Profile*" 
        {
            $dbSocial = get-SpDatabases | where-object {$_.Type -eq "Microsoft.Office.Server.Administration.SocialDatabase"}                
            $dbProfiles = get-SpDatabases | where-object {$_.Type -eq "Microsoft.Office.Server.Administration.ProfileDatabase"}               
            $dbSync = get-SpDatabases | where-object {$_.Type -eq "Microsoft.Office.Server.Administration.SynchronizationDatabase"}       

            $strDB = "Social DB = " + $dbSocial.Name + "<br>"
            $strDB += "Profiles DB = " + $dbProfiles.Name + "<br>"
            $strDB += "Sync DB = " + $dbSync.Name
        } 
        default {$strDB ="The color could not be determined."}
    }

    write-output $strDB
}

function get-SpServiceAppsInfo()
{
    try
    {
        $objects = @()
        $serviceApps = Get-SPServiceApplication | Select DisplayName, `
                                                            ApplicationVersion, `
                                                            @{Name='Svc App Status';Expression={ColorIt $_.Status}},`
                                                            @{Name='AppPool Details';Expression={get-AppPoolDetails $_.ApplicationPool}},`
                                                            @{Name='Service Instances';Expression={ get-ServiceInstances $_.ServiceInstances}},`
                                                            @{Name='Extra Info';Expression={ get-ServiceAppExtraInfo $_}}

        $objects += $serviceApps
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

function get-EntSearchInfo
{
  try
    {
        $exceptionPlaceholder = ""
        $sectionHeading = "<h2>Enterprise Search</h2><p>Description TODO</p>"

        # Enterprise SearchService Application
        $objects = @()
        $ssas = Get-SPEnterpriseSearchServiceApplication
        foreach ($ssa in $ssas)
        {
            $object = New-Object -TypeName PSObject
            $object | Add-Member -Name 'Name' -MemberType Noteproperty -Value $ssa.Name
            $object | Add-Member -Name 'Status' -MemberType Noteproperty -Value (ColorIt $ssa.Status)
            $object | Add-Member -Name 'Search Admin DB' -MemberType Noteproperty -Value $ssa.SearchAdminDatabase.Name

            # Active topology
            $sts = Get-SPEnterpriseSearchTopology -SearchApplication $ssa
            $strNo = ""
            foreach($st in $sts)
            {
                if ($st.State -like "Active")
                {
                    $strNo += ([string]$st.ComponentCount + "<br>")
                }
            }
            $object | Add-Member -Name 'No of Components' -MemberType Noteproperty -Value $strNo
            $objects += $object
        }
        $searchApp = Build-HTML-Fragment ($objects) TABLE "<li><h3>Search Service Application</h3></li>"
                
        foreach($st in $sts)
        {
            if ($st.State -like "Active")
            {
                # Search Components
                $sComps = @()
                $scs = Get-SPEnterpriseSearchComponent -SearchTopology $st | Sort-Object {$_.ServerName}
                $ssaStatus = Get-SPEnterpriseSearchStatus -SearchApplication "Search Service Application" | select Name,State

                foreach($s in $scs)
                {
                    $compObj = New-Object -TypeName PSObject
                    $compObj | Add-Member -Name 'Name' -MemberType Noteproperty -Value $s.Name
                    $compObj | Add-Member -Name 'Server' -MemberType Noteproperty -Value $s.ServerName
                    
                    $state = $ssaStatus | Where-Object {$_.Name -eq "AdminComponent1"} | Select State
                    $compObj | Add-Member -Name 'State' -MemberType Noteproperty -Value (ColorIt $state.State)

                    $rootDir = ""
                    if ($s.name -like "IndexComponent*")
                    {
                        $rootDir = $s.RootDirectory
                    }

                    $compObj | Add-Member -Name 'Root Directory' -MemberType Noteproperty -Value $rootDir
                    $sComps += $compObj
                }

                $components = $(Build-HTML-Fragment ($sComps) TABLE "<li><h3>Active Topology Components</h3></li>")
            }
        }
        
        # SharePoint Server Search service state
        $objects = @()
        $objects +=  (Get-SPEnterpriseSearchServiceInstance | Select TypeName, Server, @{Name='Status';Expression={ColorIt $_.Status}} | Sort-Object Server)
        $searchSvc = Build-HTML-Fragment ($objects) TABLE "<li><h3>SharePoint Server Search Service</h3></li>"

        # IMPORTANT: Only 1 search service app is supported by the following script
        $objects = @()
        $runTime = get-date -Format "yyyyMMdd-HHmmss"
        $searchresults = "$scriptPath\$testFolder\Results\EntSearch-$runTime.txt"
        get-EntSearchTopologyState |  Out-File  $searchresults
        
        $object = New-Object -TypeName PSObject
        $object | Add-Member -Name 'File Name' -MemberType Noteproperty -Value $searchresults
        $objects += $object
        $moreInfo = Build-HTML-Fragment ($objects) LIST "<li><h3>More information</h3></li>"
    }
    catch
    {
        $objects = get-Exception $($_.Exception.Message)
        $exceptionPlaceholder = Build-HTML-Fragment ($objects) TABLE "<b><font color='red'>Exception occurred</font></b>"
    }
    finally
    {
        Write-Output "$sectionHeading $exceptionPlaceholder <ul>$searchApp $components $searchSvc $moreInfo</ul>"

    }
}

function get-DBServers 
{   
    $path = 'HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo'
    $aliases = (Get-Item $path).Property
    
    Write-Output $aliases
}

function create-SQLObject ($sqlAllias)
{
    try
    {   
        $sqlObject = New-Object -TypeName PSObject
        $path = 'HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo'
            
        $sqlObject | Add-Member -Name 'SQL Alias' -MemberType Noteproperty -Value $sqlServer
        # protocol, server\instance, port
        $setting = Get-ItemProperty -Path $path | Select-Object -ExpandProperty $sqlAllias
        ($protocol, $serverInstance, $port) = $setting.Split(",") 
        
        if ($protocol -like "DBMSSOCN")
        {
            $protocol = "Shared Memory"
        }
        elseif ($protocol -like "dbmslpcn")
        {
            $protocol = "TCP/IP"
        }
        else
        {$protocol = "Unknown"}

        $sqlObject | Add-Member -Name 'Protocol' -MemberType Noteproperty -Value (ColorIt $protocol)

        ($dbserver, $instance) = $serverInstance.Split("\") 
        $sqlObject | Add-Member -Name 'DB Server' -MemberType Noteproperty -Value $dbserver
        $sqlObject | Add-Member -Name 'Instance' -MemberType Noteproperty -Value $instance
        $sqlObject | Add-Member -Name 'Port' -MemberType Noteproperty -Value $port

    }
    catch
    {
        $sqlObject | Add-Member -Name 'Exception' -MemberType Noteproperty -Value $($_.Exception.Message)
    }
    finally
    {
        Write-Output $sqlObject
    }

}

Function get-SQLAliases
{
    try
    {
        $dbservers = get-DBServers

        $objects = @()
        ForEach ($sqlServer in $dbservers)
        {
            If ($sqlServer) # Only check the SQL instance if it has a value
            {
                $object = create-SQLObject $sqlServer
            
                $objSQLConnection = New-Object System.Data.SqlClient.SqlConnection
                $objSQLCommand = New-Object System.Data.SqlClient.SqlCommand
                Try
                {
                    $objSQLConnection.ConnectionString = "Server=$sqlServer;Integrated Security=SSPI;"
                    $objSQLConnection.Open() | Out-Null

                    $object | Add-Member -Name 'Test Connection' -MemberType Noteproperty -Value (ColorIt "Success")
                
                    $strCmdSvrDetails = "SELECT SERVERPROPERTY('productversion') as Version"
                    $strCmdSvrDetails += ",SERVERPROPERTY('IsClustered') as Clustering"
                    $objSQLCommand.CommandText = $strCmdSvrDetails
                    $objSQLCommand.Connection = $objSQLConnection
                    $objSQLDataReader = $objSQLCommand.ExecuteReader()
                
                    If ($objSQLDataReader.Read())
                    {
                        $object | Add-Member -Name 'SQL Server version' -MemberType Noteproperty -Value $objSQLDataReader.GetValue(0)
                        
                        $SQLVersion = $objSQLDataReader.GetValue(0)
                        [int]$SQLMajorVersion,[int]$SQLMinorVersion,[int]$SQLBuild,$null = $SQLVersion -split "\."
                    
                        If ($objSQLDataReader.GetValue(1) -eq 1)
                        {
                            $object | Add-Member -Name 'Is Cluster?' -MemberType Noteproperty -Value "True"
                        }
                        Else
                        {
                            $object | Add-Member -Name 'Is Cluster?' -MemberType Noteproperty -Value "False"
                        }
                    }

                    $dbs = Get-SPDatabase -Server $sqlServer
                    $dbStr = ""
                    $dbType = ""
                    foreach($db in $dbs)
                    {
                        $dbStr += ($db.Name + "<br>")
                        $dbType += ($db.Type + "<br>")
                    }

                    $object | Add-Member -Name 'DB Name' -MemberType Noteproperty -Value $dbStr
                    $object | Add-Member -Name 'DB Type' -MemberType Noteproperty -Value $dbType

                    $objSQLDataReader.Close()
                }
                Catch
                {
                    $objSQLDataReader.Close()
                    $errText = $error[0].ToString()
                    $object | Add-Member -Name 'Test' -MemberType Noteproperty -Value "Failed"
                    $object | Add-Member -Name 'Error' -MemberType Noteproperty -Value $errText
                    continue
                }
                finally
                {
                    $objSQLConnection.Close()
                }
            } 

            $objects += $object

        } #for-each
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

function get-SQLRoles 
{
    try
    {
        $exceptionPlaceholder = ""
        $dbservers = get-DBServers
        
        $frags = ""
        ForEach ($sqlServer in $dbservers)
        {
            $fragmentContent = ""
            If ($sqlServer) # Only check the SQL instance if it has a value
            {
                $objects = @()
                $object = New-Object -TypeName PSObject
    
                $heading = "<li><h3>$sqlServer</h3></li>"
                $objSQLConnection = New-Object System.Data.SqlClient.SqlConnection
                $objSQLCommand = New-Object System.Data.SqlClient.SqlCommand
                Try
                {
                    $objSQLConnection.ConnectionString = "Server=$sqlServer;Integrated Security=SSPI;"
                    $objSQLConnection.Open() | Out-Null
                    $objSQLCommand.CommandText ="SELECT sys.server_role_members.role_principal_id, role.name AS RoleName, `
                                        sys.server_role_members.member_principal_id, member.name AS MemberName `
                                        FROM sys.server_role_members `
                                        JOIN sys.server_principals AS role `
                                        ON sys.server_role_members.role_principal_id = role.principal_id `
                                        JOIN sys.server_principals AS member `
                                        ON sys.server_role_members.member_principal_id = member.principal_id;"

                    $objSQLCommand.Connection = $objSQLConnection
                    $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
                    $SqlAdapter.SelectCommand = $objSQLCommand
                    $DataSet = New-Object System.Data.DataSet
                    $SqlAdapter.Fill($DataSet) | out-null
                    $object = ($DataSet.Tables[0].Rows | Select RoleName, MemberName)
                }
                Catch
                {
                    $errText = $error[0].ToString()
                    $object | Add-Member -Name 'Test' -MemberType Noteproperty -Value "Failed"
                    $object | Add-Member -Name 'Error' -MemberType Noteproperty -Value $errText
                    continue
                }
                finally
                {
                    $objSQLConnection.Close()
                }

                $objects += $object
                $fragmentContent = (Build-HTML-Fragment ($objects) TABLE $heading )
            }

            $frags += $FragmentContent
        } # for each
        
        
    }
    catch
    {
        $exceptionPlaceholder = ""
        $objects = get-Exception $($_.Exception.Message)
        $exceptionPlaceholder = Build-HTML-Fragment ($objects) TABLE "<b><font color='red'>Exception occurred</font></b>"
    }
    finally
    {
         Write-Output "<h2>SQL Roles and membership</h2> $exceptionPlaceholder <ul>$frags</ul>"
    }  
}


function get-ManagedMetadata()
{
    try
    {   
        # Actual results
        $objects = @()
        $mm = (Get-SPServiceApplication | ?{$_.TypeName -like "Managed Metadata*"}) | Select-Object -Property *

        $object = New-Object -TypeName PSObject       
        $object | Add-Member -Name 'Name' -MemberType Noteproperty -Value $mm.Name       
        $object | Add-Member -Name 'Version' -MemberType Noteproperty -Value ($mm.ApplicationVersion)
        $object | Add-Member -Name 'Service App Status' -MemberType Noteproperty -Value (ColorIt $mm.Status)
        $object | Add-Member -Name 'Database' -MemberType Noteproperty -Value ($mm.database.Name)
        
        $object | Add-Member -Name 'AppPool Name' -MemberType Noteproperty -Value ($mm.ApplicationPool.Displayname)
        $object | Add-Member -Name 'AppPool Status' -MemberType Noteproperty -Value (ColorIt $mm.ApplicationPool.Status)
        $object | Add-Member -Name 'AppPool Identity' -MemberType Noteproperty -Value ($mm.ApplicationPool.ProcessAccountName)

        $mmInstances = $mm.ServiceInstances | Select TypeName, Service, Server, Status
        $mmSvc = ""
        foreach($mmInst in $mmInstances)
        {
            $mmSvc += ($mmInst.Server.Name + "<br>Status = " + (ColorIt $mmInst.Status) + "<br><br>")
        }
        $object | Add-Member -Name $mmInstances[0].TypeName -MemberType Noteproperty -Value $mmSvc
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

function get-StateService()
{
    try
    {   
        # Actual results
        $objects = @()
        $ss = (Get-SPServiceApplication | ?{$_.TypeName -like "State Service*"}) | Select-Object -Property *

        $object = New-Object -TypeName PSObject       
        $object | Add-Member -Name 'Name' -MemberType Noteproperty -Value $ss.Name       
        $object | Add-Member -Name 'Version' -MemberType Noteproperty -Value ($ss.ApplicationVersion)
        $object | Add-Member -Name 'Service App Status' -MemberType Noteproperty -Value (ColorIt $ss.Status)
        
        $mmSvc = ""
        if($ss.Databases.count -gt 0)
        {
            foreach($db in $ss.Databases)
            {
                $mmSvc += ("DB Server = " + $db.ServerName + "<br>DB Name = " + $db.Name + "<br>Status = " + (ColorIt $db.Status) + "<br><br>")
            }

            $object | Add-Member -Name 'Databases' -MemberType Noteproperty -Value $mmSvc
        }

        $mmInstances = $ss.ServiceInstances | Select TypeName, Service, Server, Status
        $mmSvc = ""
        if ($mmInstances.count -gt 0)
        {
            foreach($mmInst in $mmInstances)
            {
                $mmSvc += ($mmInst.Server.Name + "<br>Status = " + (ColorIt $mmInst.Status) + "<br><br>")
            }
            $object | Add-Member -Name $mmInstances[0].TypeName -MemberType Noteproperty -Value $mmSvc
        }

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

function get-SecureStore()
{
    try
    {   
        # Actual results
        $objects = @()
        $mm = (Get-SPServiceApplication | ?{$_.TypeName -like "Secure Store*"}) | Select-Object -Property *

        $object = New-Object -TypeName PSObject       
        $object | Add-Member -Name 'Name' -MemberType Noteproperty -Value $mm.Name       
        $object | Add-Member -Name 'Version' -MemberType Noteproperty -Value ($mm.ApplicationVersion)
        $object | Add-Member -Name 'Service App Status' -MemberType Noteproperty -Value (ColorIt $mm.Status)
        
        $object | Add-Member -Name 'AppPool Name' -MemberType Noteproperty -Value ($mm.ApplicationPool.Displayname)
        $object | Add-Member -Name 'AppPool Status' -MemberType Noteproperty -Value (ColorIt $mm.ApplicationPool.Status)
        $object | Add-Member -Name 'AppPool Identity' -MemberType Noteproperty -Value ($mm.ApplicationPool.ProcessAccountName)

        $mmInstances = $mm.ServiceInstances | Select TypeName, Service, Server, Status
        $mmSvc = ""
        foreach($mmInst in $mmInstances)
        {
            $mmSvc += ($mmInst.Server.Name + "<br>Status = " + (ColorIt $mmInst.Status) + "<br><br>")
        }
        $object | Add-Member -Name $mmInstances[0].TypeName -MemberType Noteproperty -Value $mmSvc
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

function get-UserProfiles()
{
    try
    {   
        # Actual results
        $objects = @()
        $upa = (Get-SPServiceApplication | ?{$_.TypeName -like "User Profile*"}) | Select-Object -Property *

        $object = New-Object -TypeName PSObject       
        $object | Add-Member -Name 'Name' -MemberType Noteproperty -Value $upa.Name       
        $object | Add-Member -Name 'Version' -MemberType Noteproperty -Value ($upa.ApplicationVersion)
        $object | Add-Member -Name 'Service App Status' -MemberType Noteproperty -Value (ColorIt $upa.Status)
        
        $object | Add-Member -Name 'AppPool Name' -MemberType Noteproperty -Value ($upa.ApplicationPool.Displayname)
        $object | Add-Member -Name 'AppPool Status' -MemberType Noteproperty -Value (ColorIt $upa.ApplicationPool.Status)
        $object | Add-Member -Name 'AppPool Identity' -MemberType Noteproperty -Value ($upa.ApplicationPool.ProcessAccountName)


        $dbSocial = get-SpDatabases | where-object {$_.Type -eq "Microsoft.Office.Server.Administration.SocialDatabase"}                
        $dbProfiles = get-SpDatabases | where-object {$_.Type -eq "Microsoft.Office.Server.Administration.ProfileDatabase"}               
        $dbSync = get-SpDatabases | where-object {$_.Type -eq "Microsoft.Office.Server.Administration.SynchronizationDatabase"}       

        $strDB = "Social DB = " + $dbSocial.Name + "<br>"
        $strDB += "Profiles DB = " + $dbProfiles.Name + "<br>"
        $strDB += "Sync DB = " + $dbSync.Name

        $object | Add-Member -Name "Databases" -MemberType Noteproperty -Value $strDB

        $mmInstances = $upa.ServiceInstances | Select TypeName, Service, Server, Status
        $mmSvc = ""
        foreach($mmInst in $mmInstances)
        {
            $mmSvc += ($mmInst.Server.Name + "<br>Status = " + (ColorIt $mmInst.Status) + "<br><br>")
        }
        $object | Add-Member -Name $mmInstances[0].TypeName -MemberType Noteproperty -Value $mmSvc
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

function get-SecurityTokenSvcManager
{
    try
    {   
        # Actual results
        $objects = @()
        $objects += (Get-SPSecurityTokenServiceConfig | Select AllowMetadataOverHttp, `                    
                                                    UseSessionCookies, `                  
                                                    WindowsTokenLifetime, `
                                                    FormsTokenLifetime, `                   
                                                    CookieLifetime, `                            
                                                    ServiceTokenLifetime, `                      
                                                    MaxLogonTokenCacheItems, `                   
                                                    MaxLogonTokenOptimisticCacheItems, `         
                                                    LogonTokenCacheExpirationWindow, `           
                                                    MaxServiceTokenCacheItems, `                 
                                                    MaxServiceTokenOptimisticCacheItems, `       
                                                    ServiceTokenCacheExpirationWindow, `         
                                                    ApplicationTokenLifetime, `                  
                                                    AuthenticatorTokenLifetime, `                
                                                    MinApplicationTokenCacheItems, `             
                                                    MaxApplicationTokenCacheItems, `             
                                                    ApplicationTokenCacheExpirationWindow, `     
                                                    LoopbackTokenLifetime, `                     
                                                    AllowOAuthOverHttp, `                        
                                                    PidEnabled, `                                
                                                    HybridStsSelectionEnabled, `                 
                                                    Name, `                                      
                                                    DisplayName, `                               
                                                    Status, `                                    
                                                    Version)

 
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
    $product = "SharePoint"

    . .\LoggingV2.ps1 $true $scriptPath "unitTest-Server-$product.ps1"
    . "$scriptPath\$testFolder\HTMLGenerator.ps1"
    . "$scriptPath\$testFolder\Get-SPSearchTopologyState.ps1"
    . "$scriptPath\$testFolder\UnitTest-Common-Utilities.ps1"

    Add-PsSnapin Microsoft.SharePoint.PowerShell -ErrorAction Stop | Out-Null
    
    $installFile = "$scriptPath\InstallMedia\SP2016-SilentConfig.xml"    
    # $cerificatesFile = "$scriptPath\Config\SharePointCertificates.xml"

    # TODO: Should use variables, including useSSL
    $configFile = "$scriptPath\ConfigFiles\SP2016-FarmConfig.xml"
    log "INFO SharePoint config xml = $configFile"
    [xml]$xmlinput = (((Get-Content $configFile) -replace ("localhost", $env:COMPUTERNAME)) -replace( "http://", "https://"))

    $wac_server = "OfficeOnlione"
    $discoveryUrl = "https://$wac_server.mwsaust.net/hosting/discovery"
    log "INFO: Office Web Apps discovery url: $discoveryUrl"

    # Web Apps

    # Site Colls

    $dtStart =  get-date

    log "INFO: about to call InstallLocation"
    $installLocation = Build-HTML-Fragment (get-InstallLocation) LIST "<h2>Install Location</h2>"
    
    log "INFO: about to call ProductInfo"
    $productInfo = Build-HTML-Fragment (get-ProductInfo) LIST "<h2>Product Information</h2>" 

    log "INFO: about to call get-CentralAdminInfo"
    $centralAdmin = Build-HTML-Fragment (get-CentralAdminInfo) LIST "<h2>Central Administration</h2>"

    <# Obsolete 
    log "INFO: about to call get-SpDatabases"
    $spDatabases = Build-HTML-Fragment (get-SpDatabases) TABLE "<h2>SharePoint Databases</h2>"
    #>

    log "INFO: about to call get-SQLAliases"
    $sqlAccess = Build-HTML-Fragment (get-SQLAliases) TABLE "<h2>SQL Aliases and Databases</h2>"


    log "INFO: about to call get-SQLRoles"
    $sqlRoles = get-SQLRoles
    
    log "INFO: about to call get-SystemAccounts"
    $sysAccounts = get-SystemAccounts
    
    log "INFO: about to call get-FarmTopology"
    $farmTopology = Build-HTML-Fragment (get-FarmTopology) TABLE "<h2>SharePoint Farm Topology</h2>"

    log "INFO: about to call get-SpServiceAppsInfo"
    $spServiceApps = Build-HTML-Fragment (get-SpServiceAppsInfo) TABLE "<h2>SharePoint Service Applications</h2>"

    log "INFO: about to call get-SpServicesOnServer"
    $spServices = Build-HTML-Fragment (get-SpServicesOnServer) TABLE "<h2>SharePoint Services On Server</h2>"

    log "INFO: about to call get-WindowsServices"
    $winServices = get-WindowsServices


    log "INFO: about to call get-EntSearchInfo"
    $entSearch = get-EntSearchInfo 
    
    log "INFO: about to call get-SpWebApps"
    $spWebApps = get-SpWebApps

 
    log "INFO: about to call get-SpSiteCollections"
    $spSiteCols = Build-HTML-Fragment (get-SpSiteCollections) TABLE "<h2>SharePoint Site Collections</h2>"

   <#    log "INFO: about to call discover-OfficeWebApps"
    $frag13 = Build-HTML-Fragment (discover-OfficeWebApps $discoveryUrl) TABLE "<h2>Office Web Apps</h2>"

    $content = "$installLocation $productInfo $frag3 $frag4 $frag5 $frag6 $frag7 $frag8 $frag9 $frag10 $frag11 $frag12 $frag13"

    #>

    log "INFO: about to call get-DistributedCache"
    $distributedCache = (get-DistributedCache $xmlinput)

    log "INFO: about to call get-UserProfiles"
    $UserProfiles = Build-HTML-Fragment (get-UserProfiles) LIST "<h2>User Profiles in Details</h2>"

    log "INFO: about to call get-ManagedMetadata"
    $mgdMetadata = Build-HTML-Fragment (get-ManagedMetadata) LIST "<h2>Managed Metadata in Details</h2>"

    log "INFO: about to call get-StateService"
    $stateSvc = Build-HTML-Fragment (get-StateService) LIST "<h2>State Service in Details</h2>"

    log "INFO: about to call get-SecureStore"
    $SecureStore = Build-HTML-Fragment (get-SecureStore) LIST "<h2>Secure Store in Details</h2>"

    log "INFO: about to call get-SecurityTokenSvcManager"
    $secTokenSvcmgr = Build-HTML-Fragment (get-SecurityTokenSvcManager) LIST "<h2>Security Token Service Manager in Details</h2>"

    $content = "$installLocation `
                $productInfo `
                $sysAccounts `
                $farmTopology `                
                $sqlAccess `
                $sqlRoles `
                $centralAdmin `
                $spServiceApps `
                $spServices `
                $winServices `
                $entSearch `
                $spWebApps `
                $spSiteCols `
                $UserProfiles `
                $distributedCache `
                $mgdMetadata `
                $stateSvc `
                $SecureStore `
                $secTokenSvcmgr"

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
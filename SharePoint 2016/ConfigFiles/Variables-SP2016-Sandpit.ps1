Param(
    [string] $serverRole = ""
)

function Get-ServersList ([string] $shortNames)
{
    $servers = $shortNames -split ","
    $serversList = ""

    if ($servers.Count -ne 0)
    {
        foreach ($server in $servers)
        {
            $server = $server.Trim()
            $srv = ([string](Get-ServerName $server)).ToUpper() + ","
            $serversList += $srv
        }

        if (([string]$serversList).EndsWith(",") -eq $true)
        {
            $serversList = $serversList -replace ".$"
        }
    }

    return $serversList
}

function get-ServerRole
{
    $webServers = Get-ServersList $WEBFRONTEND
    if ($webServers.contains(([string]$env:COMPUTERNAME).ToUpper()))
    {
        $SERVER_ROLE = "WEB"
    }
    else
    {
        $appServers = Get-ServersList $APPLICATION
        if ($appServers.contains(([string]$env:COMPUTERNAME).ToUpper()))
        {
            $SERVER_ROLE = "APP"
        }
        else
        {
            $dcServers = Get-ServersList $DISTRIBUTEDCACHE
            if ($dcServers.contains(([string]$env:COMPUTERNAME).ToUpper()))
            {
                $SERVER_ROLE = "DC"
            }
            else
            {
                $searchServers = Get-ServersList $SEARCH
                if ($searchServers.contains(([string]$env:COMPUTERNAME).ToUpper()))
                {
                    $SERVER_ROLE = "SEARCH"
                }
                else
                {
                    $customServers = Get-ServersList $CUSTOM
                    if ($searchServers.contains(([string]$env:COMPUTERNAME).ToUpper()))
                    {
                        $SERVER_ROLE = "CUSTOM"
                    }
                    else
                    {
                        $SERVER_ROLE = "SINGLESERVER"
                    }
                }
            }
        }
    }

    return $SERVER_ROLE
}

# ============== COMMON ====================================================================== 
# run script but do not execute installs
$TEST = $false
#do not use ELevated Task, just load the script for debugging
$DEBUG = $false

$ver = "2016"
$USE_VARIABLES = $true
$INSTALL_MEDIA = "InstallMedia" 
$PREREQS_LOCATION = "PrerequisiteInstallerFiles"

$CONFIG_XML = "ConfigFiles\SP2016-FarmConfig.xml"
$PASSPHRASE = "Password1234567"

# Domain/forward lookup zone where DNS entries for the sites are created
$FORWARD_LOOKUP_ZONE = "mwsaust.net"
$TRUSTED_DOMAIN = "mwsaust.net"

#region Service Accounts
$ADMIN = "agilitydeploy"
$USER = $ADMIN

$FARM_ACCOUNT = "svc_sp_farm"
        
$ENTSEARCH_SVCAPP_CONTENT_ACCESS_ACCOUNT = "svc_sp_Content"
$SEARCH_SERVICE_ACCOUNT = "svc_sp_search"
        
$SPSERVICE_ACCOUNT = "svc_sp_Services"    
        
$PORTAL_ACCOUNT = "svc_sp_farm"
$PORTAL_APPPOOL_ACCOUNT = "svc_sp_WebAppPool"
$MYSITES_ACCOUNT = "svc_sp_farm"
$MYSITES_APPPOOL_ACCOUNT = "svc_mysitesapppool"

$SITE_COL_OWNER = "agilitydeploy"
$MYSITES_COL_OWNER = "agilitydeploy"

$EXCEL_ACCT = "svc_sp_Excel"
$PERFPOINT_ACCT = "svc_sp_farm"
$SUPER_READER = "svc_sp_SuperReader"
$SUPER_USER = "svc_sp_SuperUser"
$UP_SYNCCONNACCOUNT = "svc_sp_UserProfile"
$VISIO_ACCT = "svc_sp_visio"

$TRUSTED_ACCOUNT = "svc_mwssp"
#endregion

#region InstallSP2013Binaries
    $INSTALLLOCATION = "E:\Program Files\Microsoft Office Servers\"
    $DATADIR = "E:\Program Files\Microsoft Office Servers\16.0\Data"
    $PIDKEY = "NQGJR-63HC8-XCRQH-MYVCH-3J3QR" #2016 enterprise
    $LOGGINGPATH = "E:\LogFiles\Setup2016"
    $SILENTINSTALL_XML = "ConfigFiles\SP2016-SilentConfig.xml"
    $CONFIGFILES_LOCATION = "ConfigFiles"
#endregion

#region Install-SPUpdate
$UPDATES_LOCATION = "InstallMedia\Updates"
$UPDATES_XML = "SP2016_Updates.xml"
$PSCONFIG_REQUIRED = "false"
#endregion

#region DB servers
$DB_PREFIX = "SP2016"

$ConfigInstanceServer = "DBS-101"
$ContentInstanceServer = "DBS-101"

$ConfigInstanceName = "MWSSPCONFIG08"
$ConfigInstancePort = "49008"
$CONFIGDB_ALIAS = "SP_CONFIG"
$CONFIGDB_ALIAS_CREATE = "true"

$ContentInstanceName = "MWSSPCONTENT09"
$ContentInstancePort = "49009"
$CONTENTDB_ALIAS = "SP_CONTENT"
$CONTENTDB_ALIAS_CREATE = "true"

$CONTENT_DB_INSTANCE = $ContentInstanceName
$CONTENT_DB_PORT = $ContentInstancePort
$CONTENT_DB_SERVER = $ContentInstanceServer

$ACCESS_DB_INSTANCE_NAME = $ConfigInstanceName
$ACCESS_DB_INSTANCE_PORT = $ConfigInstancePort
$ACCESS_DB_SERVER = $ConfigInstanceServer

$APPMGMT_DB_INSTANCE_NAME = $ConfigInstanceName
$APPMGMT_DB_INSTANCE_PORT = $ConfigInstancePort
$APPMGMT_DB_SERVER = $ConfigInstanceServer

$BDC_DB_INSTANCE_NAME = $ConfigInstanceName
$BDC_DB_INSTANCE_PORT = $ConfigInstancePort
$BDC_DB_SERVER = $ConfigInstanceServer

$CONFIG_DB_INSTANCE_NAME = $ConfigInstanceName
$CONFIG_DB_INSTANCE_PORT = $ConfigInstancePort
$CONFIG_DB_SERVER = $ConfigInstanceServer

$ENTSEARCH_DB_INSTANCE_NAME = $ConfigInstanceName
$ENTSEARCH_DB_INSTANCE_PORT = $ConfigInstancePort
$ENTSEARCH_DB_SERVER = $ConfigInstanceServer

$MM_DB_INSTANCE_NAME = $ConfigInstanceName
$MM_DB_INSTANCE_PORT = $ConfigInstancePort
$MM_DB_SERVER = $ConfigInstanceServer

$PERFPOINT_DB_INSTANCE_NAME = $ConfigInstanceName
$PERFPOINT_DB_INSTANCE_PORT = $ConfigInstancePort
$PERFPOINT_DB_SERVER = $ConfigInstanceServer

$SECSTORE_DB_INSTANCE_NAME = $ConfigInstanceName
$SECSTORE_DB_INSTANCE_PORT = $ConfigInstancePort
$SECSTORE_DB_SERVER = $ConfigInstanceServer

$SPUSAGE_DB_INSTANCE_NAME = $ConfigInstanceName
$SPUSAGE_DB_INSTANCE_PORT = $ConfigInstancePort
$SPUSAGE_DB_SERVER = $ConfigInstanceServer

$STATESVC_DB_INSTANCE_NAME = $ConfigInstanceName
$STATESVC_DB_INSTANCE_PORT = $ConfigInstancePort
$STATESVC_DB_SERVER = $ConfigInstanceServer

$SUBSCR_DB_INSTANCE_NAME = $ConfigInstanceName
$SUBSCR_DB_INSTANCE_PORT = $ConfigInstancePort
$SUBSCR_DB_SERVER = $ConfigInstanceServer

$TRANSL_DB_INSTANCE_NAME = $ConfigInstanceName
$TRANSL_DB_INSTANCE_PORT = $ConfigInstancePort
$TRANSL_DB_SERVER = $ConfigInstanceServer

$UP_DB_INSTANCE_NAME = $ConfigInstanceName
$UP_DB_INSTANCE_PORT = $ConfigInstancePort
$UP_DB_SERVER = $ConfigInstanceServer

$WORDAUTO_DB_INSTANCE_NAME = $ConfigInstanceName
$WORDAUTO_DB_INSTANCE_PORT = $ConfigInstancePort
$WORDAUTO_DB_SERVER = $ConfigInstanceServer

#endregion

#region topology -  Server Roles 2016 - comma delimited list of servers
$WEBFRONTEND = "WEB-101, WEB-102"
$APPLICATION = "APP-101, APP-102"
$DISTRIBUTEDCACHE = "APP-107, APP-108"
$SEARCH = "APP-103, APP-104"
$CUSTOM = ""
$SINGLESERVERFARM = ""

# get server role base on the topology defined above
$SERVER_ROLE = get-ServerRole 
$serverRole = $SERVER_ROLE

$userProfileSynchServer = "APP-101"
$UP_SYNCH_SERVER = $userProfileSynchServer

#endregion

#region Web Apps
# the variables cater only for 2 web apps. Additional web apps need to be configured directly in CONFIG_XML
$USE_SSL = $true

$WEBAPPS_CONFIG_XML = "ConfigFiles\SP2016-WebApps-Sandpit.xml"

#endregion

#region Logging location
# default location will be used if empty
$IISLOGS_LOCATION = "L:\LogFiles\IIS"
$USAGELOGS_LOCATION = "L:\LogFiles\Usage"
$ULSLOGS_LOCATION = "L:\LogFiles\ULS"
#endregion

#region Service Apps
$APPMGMT_DOMAIN = ("apps." + $FORWARD_LOOKUP_ZONE)

$SMTP_SERVER = ("mail." + $FORWARD_LOOKUP_ZONE)
$EMAIL_ADDRESS = ("admin@" + $FORWARD_LOOKUP_ZONE)
$REPLY_TO_EMAIL = ("HelpDesk@" + $FORWARD_LOOKUP_ZONE)

$APPMGMT_DB_NAME = "AppManagement"
$APPMGMT_SVCAPP_NAME = "App Management Service App"
$APPMGMT_SVCAPP_PROXY = "App Management Service App Proxy"

$ACCESS2010_SVCAPP_NAME = "Access 2010 Service App"
$ACCESS2010_SVCAPP_PROXY = "Access 2010 Service App Proxy"

$ACCESS_DB_NAME = "AccessServices"
$ACCESS_SVCAPP_NAME = "Access Service App"
$ACCESS_SVCAPP_PROXY = "Access Service App Proxy"

$BDC_DB_NAME = "BusinessDataCatalog"
$BDC_SVCAPP_NAME = "Business Data Connectivity Service App"
$BDC_SVCAPP_PROXY = "Business Data Connectivity Service App Proxy"

$ENTSEARCH_CONTACTEMAIL = ("admin@" + $FORWARD_LOOKUP_ZONE)
$ENTSEARCH_CUSTOMINDEXLOCATION = "G:\SharePoint2016\Index"

$ENTSEARCH_SVCAPP_NAME = "Search Service App"
$ENTSEARCH_SVCAPP_PROXY = "Search Service App Proxy"
$ENTSEARCH_DB_NAME = "Search"

$EXCEL_SVCAPP_NAME = "Excel Service App"

$VISIO_SVCAPP_NAME = "Visio Service App"
$VISIO_SVCAPP_PROXY = "Visio Service App Proxy"

$MM_DB_NAME = "ManagedMetadata"                 
$MM_SVCAPP_NAME = "Managed Metadata Service App" 
$MM_SVCAPP_PROXY = "Managed Metadata Service App Proxy" 

$MACHINETRANSL_DB_NAME = "TranslationService"                 
$MACHINETRANSL_SVCAPP_NAME = "Machine Translation Service App" 
$MACHINETRANSL_SVCAPP_PROXY = "Machine Translation Service App Proxy" 

$PERFPOINT_DB_NAME = "PerformancePoint"          
$PERFPOINT_SVCAPP_NAME = "PerformancePoint Service App"
$PERFPOINT_SVCAPP_PROXY = "PerformancePoint Service App Proxy"

$PPT_SVCAPP_NAME = "PowerPoint Service App"
$PPT_SVCAPP_PROXY = "PowerPoint Service App Proxy"

$ENABLE_LIC_ENFORCEMENT = "false"
$PREMIUM_USERS = "false"
$STANDARD_USERS = "false"

$SECSTORE_DB_NAME = "SecureStore"   
$SECSTORE_SVCAPP_NAME = "Secure Store Service App"
$SECSTORE_SVCAPP_PROXY = "Secure Store Service App Proxy"

$STATESERVICEE_DB_NAME = "StateService"   
$STATESERVICE_SVCAPP_NAME = "State Service App"
$STATESERVICE_SVCAPP_PROXY = "State Service App Proxy"

$SUBSCRSERVICE_DB_NAME = "SubscriptionService"   
$SUBSCRSERVICE_SVCAPP_NAME = "Subscription Settings Service App"

$UP_SYNCH_DB_NAME = "Synch"
$UP_PROFILE_DB_NAME = "Profile"
$UP_SOCIAL_DB_NAME = "Social" 
$UP_SVCAPP_NAME = "User Profile Service App"
$UP_SVCAPP_PROXY = "User Profile Service App Proxy"

$WORDAUTOM_DB_NAME = "WordAutomation"   
$WORDAUTOM_SVCAPP_NAME = "Word Automation Service App"
$WORDAUTOM_SVCAPP_PROXY = "Word Automation Service App Proxy"

$WORKMGMT_SVCAPP_NAME = "Work Management Service App"
$WORKMGMT_SVCAPP_PROXY = "Work Management Service App Proxy"
#endregion

#region ServiceApps and Services - Initialise
    $PROVISION_WEB_APPS = $false

    $ACCESS_PROVISION = "false"
    $ACCESS2010_PROVISION = "false"
    $APPMGMT_PROVISION = "false"
    $BDC_PROVISION = "false"
    $CA_PROVISION = "false" # provisioned automatically on the first server in the farm
    $CLAIMS_TO_WINDOWS_TOKENSERVICE = "false" # MinRole starts the service on an appropriate server
    $DISTRIBUTED_CACHE = "false" # MinRole starts the service on an appropriate server
    $ENTSEARCH_PROVISION = "false"
    $ENTSEARCH_SVCAPP_ADMINSERVER = "false"
    $ENTSEARCH_SVCAPP_ANALYTICSSERVER = "false"
    $ENTSEARCH_SVCAPP_CONTENTSERVER = "false"
    $ENTSEARCH_SVCAPP_CRAWLSERVER = "false"
    $ENTSEARCH_SVCAPP_INDEXSERVER = "false"
    $ENTSEARCH_SVCAPP_QUERYSERVER = "false"
    $ENTSEARCH_SVCAPP_SEARCHQUERYSETTINGSSERVER = "false"
    $EXCEL_PROVISION = "false"
    $FOUNDATION_WEB_APP = "false"
    $INCOMING_EMAIL = "false"
    $MM_PROVISION = "false"
    $OUTGOING_EMAIL = "false"
    $PERFPOINT_PROVISION = "false"
    $PPTCONV_PROVISION = "false"
    $SANDBOXEDCODESERVICE = "false"   
    $SECSTORE_PROVISION = "false"
    $SMTP_SERVICE = "false"
    $SPUSAGE_PROVISION = "false"
    $STATESVC_PROVISION = "false"
    $SUBSCR_PROVISION = "false"
    $TRANSL_PROVISION = "false"
    $UP_PROVISION = "false"
    $UP_STARTPROFILESYNCH = "false"
    $VISIO_PROVISION = "false"
    $WORDAUTO_PROVISION = "false"
    $WORKFLOW_TIMER = "false"
    $WORKMGMT_PROVISION = "false"
#endregion

# MinRoles drives enabling the services associated with the Service Apps. This means, if Managed Metadata is supported on both, WFE and APP, 
# it will be enabled on the appropriate servers by SharePoint

#region WFE
if (($serverRole.ToUpper() -eq "WEB") -or ($serverRole.ToUpper() -eq "WFE"))
{
    $PROVISION_WEB_APPS = $true

    $CA_PROVISION = "localhost"
    $CA_PORT = "2016"

    # WFE only
    $ACCESS_PROVISION = "false"          # TODO: requires SQL in Mixed mode
    $ACCESS2010_PROVISION = "localhost"
    $PERFPOINT_PROVISION = "localhost"  
    $VISIO_PROVISION = "localhost"      

    $SPUSAGE_PROVISION = "localhost"
    $SUBSCR_PROVISION = "localhost"

    # WFE and APP
    $APPMGMT_PROVISION = "localhost"       
    $BDC_PROVISION = "localhost"      
    $TRANSL_PROVISION = "localhost"
    $MM_PROVISION = "localhost"       
    $SECSTORE_PROVISION = "localhost" 
}
#endregion

#region APP
if ($serverRole.ToUpper() -eq "APP")
{
    $UP_PROVISION = "localhost"         
    $UP_STARTPROFILESYNCH = "true"       

    # APP only 
    $WORDAUTO_PROVISION = "localhost"
    $OUTGOING_EMAIL = "true"
    $PPTCONV_PROVISION = "localhost"
}
#endregion

#region SEARCH
if ($serverRole.ToUpper() -eq "SEARCH")
{
    $ENTSEARCH_PROVISION = "localhost"
    $ENTSEARCH_SVCAPP_ADMINSERVER = "localhost"
    $ENTSEARCH_SVCAPP_ANALYTICSSERVER = "localhost"
    $ENTSEARCH_SVCAPP_CONTENTSERVER = "localhost"
    $ENTSEARCH_SVCAPP_CRAWLSERVER = "localhost"
    $ENTSEARCH_SVCAPP_INDEXSERVER = "localhost"
    $ENTSEARCH_SVCAPP_QUERYSERVER = "localhost"
    $ENTSEARCH_SVCAPP_SEARCHQUERYSETTINGSSERVER = "localhost"
}    
#endregion

#region DC
if ($serverRole.ToUpper() -eq "DC")
{
}    
#endregion

#region Custom
#endregion

#region Office Online integration -  SP2016 Connect To Office Online farm
$WAC_USE_SSL = "true"
$WAC_SERVER = ("OfficeOnline." + $FORWARD_LOOKUP_ZONE)
$WAC_CONNECT = "false"
#endregion

# Workflow Manager - InstallEwsManagedApi
# $INSTALLER = "\EwsManagedApi\EwsManagedApi.msi"
# $MSI = "c:\windows\system32\msiexec.exe"

# ExecuteUnitTestServer.ps1

##############################################################
# Validate if this is correct server, MinRole, etc
##############################################################

if ($serverRole -eq "")
{
    # ShPt prereqs are server role independent ==> all good
}
else
{
    $currentServer = ($env:COMPUTERNAME).ToUpper()
    if ($serverRole.ToUpper() -eq "APP")
    {
        $serversList = Get-ServersList $APPLICATION
    }
    elseif (($serverRole.ToUpper() -eq "WEB") -or ($serverRole.ToUpper() -eq "WFE"))
    {
        $serversList = Get-ServersList $WEBFRONTEND
    }
    elseif ($serverRole.ToUpper() -eq "SEARCH")
    {
        $serversList = Get-ServersList $SEARCH
    }
    elseif ($serverRole.ToUpper() -eq "DC")
    {
        $serversList = Get-ServersList $DISTRIBUTEDCACHE
    }
    elseif ($serverRole.ToUpper() -eq "CUSTOM")
    {
        $serversList = Get-ServersList $CUSTOM
    }
    else
    {
        throw "ERROR: Unsupported Server Role: $serveRole"
    }

    if (!($serversList.Contains($currentServer)))
    {
        throw "ERROR: Current Server $currentServer, Server Role $serverRole and MinRole $serversList do not match"
    }
    else
    {
        # all good
    }
}
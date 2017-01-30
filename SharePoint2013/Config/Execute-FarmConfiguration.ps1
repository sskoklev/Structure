Param(
    [string] $scriptPath
)


#################################################################################################
# Author: Marina Krynina
# Desc:   Functions to support preparation of SharePoint 2013 farm configuration
#################################################################################################
function UpdateInputFile ([string] $inputFile)
{
    # this is a variable to force hardcoded defaults. It is useful for testing outside of Agility
    $useHardcodedDefaults = $false

    if ((ifFileExists( $inputFile)) -ne $true)
    {
        throw "ERROR: $inputFile is missing"
    }

    CreateBackupCopy $inputFile
    [xml]$xmlinput = [xml](Get-Content $inputFile)

    # INSTALL  
    # This information was updated during binaries install and taken from SilentConfig.xml
    # InstallDir
    # DataDir
    # pidKey

    # This variable is used in DEBUG mode only!
    $sp_db_server = "DBS-003"

    #Client Domain
    # all urls except servers fqdn should use cline tdomain
    $CLIENT_DOMAIN = (Get-VariableValue $CLIENT_DOMAIN "mwsaust.net" $useHardcodedDefaults)

    # FARM
    log "INFO: Setting Farm account and passphrase"
    $xmlinput.Configuration.Farm.Passphrase = (Get-VariableValue $PASSPHRASE "p@ssw0rd" $useHardcodedDefaults) 

    # FARM.ACCOUNT
    $farmAccount = (Get-VariableValue $FARM_ACCOUNT "svc_sp_farm" $useHardcodedDefaults)
    $xmlinput.Configuration.Farm.Account.Password = (get-serviceAccountPassword -username $farmAccount)      
    $xmlinput.Configuration.Farm.Account.Username = "$domain\$farmAccount"

    # FARM.DATABASE
    # ComponentID-InstanceID
    $configDB = (Get-VariableValue $CONFIG_DB_SERVER $sp_db_server $useHardcodedDefaults)
    $configDB_server = ([string](Get-ServerName $configDB)).ToUpper()

    log "INFO: Setting Farm Database variables"
    $xmlinput.Configuration.Farm.Database.DBPrefix = (Get-VariableValue $DB_PREFIX "MWS2" $useHardcodedDefaults)
    $DB_PREFIX = $xmlinput.Configuration.Farm.Database.DBPrefix

    $xmlinput.Configuration.Farm.Database.DBAlias.DBInstance = $configDB_server + "\" + (Get-VariableValue $CONFIG_DB_INSTANCE_NAME "sp_config" $useHardcodedDefaults)
    $xmlinput.Configuration.Farm.Database.DBAlias.DBPort = (Get-VariableValue $CONFIG_DB_INSTANCE_PORT "49008" $useHardcodedDefaults)

    # CENTRAL ADMIN - install on a WFE (recommended by MSFT) or BackEnd
    # CA_PROVISION supported values: true, false, localhost
    log "INFO: Setting CENTRAL_ADMIN variables"
    $xmlinput.Configuration.Farm.CentralAdmin.Provision = (Get-VariableValue $CA_PROVISION "localhost" $useHardcodedDefaults)
    $xmlinput.Configuration.Farm.CentralAdmin.Port = (Get-VariableValue $CA_PORT "2013" $useHardcodedDefaults)

    # SERVICES
    # supported values: true, false, localhost
    log "INFO: Setting Farm Services variables"
    $xmlinput.Configuration.Farm.Services.SandboxedCodeService.Start = (Get-VariableValue $SANDBOXEDCODESERVICE "localhost" $useHardcodedDefaults)
    $xmlinput.Configuration.Farm.Services.ClaimsToWindowsTokenService.Start = (Get-VariableValue $CLAIMS_TO_WINDOWS_TOKENSERVICE "localhost" $useHardcodedDefaults)
    $xmlinput.Configuration.Farm.Services.DistributedCache.Start = (Get-VariableValue $DISTRIBUTED_CACHE "localhost" $useHardcodedDefaults)
    $xmlinput.Configuration.Farm.Services.WorkflowTimer.Start = (Get-VariableValue $WORKFLOW_TIMER "localhost" $useHardcodedDefaults)
    $xmlinput.Configuration.Farm.Services.FoundationWebApplication.Start = (Get-VariableValue $FOUNDATION_WEB_APP "localhost" $useHardcodedDefaults)
        
    log "INFO: Setting Outgoing/Incoming Email variables"
    $xmlinput.Configuration.Farm.Services.SMTP.Install = (Get-VariableValue $SMTP_SERVICE "localhost" $useHardcodedDefaults)
    $xmlinput.Configuration.Farm.Services.OutgoingEmail.Configure = (Get-VariableValue $OUTGOING_EMAIL "true" $useHardcodedDefaults)

    [string]$smtpBit = (Get-VariableValue $SMTP_SERVER "smtp" $useHardcodedDefaults)
    if ($smtpBit.ToUpper() -ne "false")
    {
        $xmlinput.Configuration.Farm.Services.OutgoingEmail.SMTPServer = (Get-VariableValue $SMTP_SERVER "mail" $useHardcodedDefaults) + ".$CLIENT_DOMAIN"
    }

    $xmlinput.Configuration.Farm.Services.OutgoingEmail.EmailAddress = (Get-VariableValue $EMAIL_ADDRESS "admin") + "@$CLIENT_DOMAIN"
    $xmlinput.Configuration.Farm.Services.OutgoingEmail.ReplyToEmail = (Get-VariableValue $REPLY_TO_EMAIL "HelpDesk" $useHardcodedDefaults) + "@$CLIENT_DOMAIN"
    $xmlinput.Configuration.Farm.Services.IncomingEmail.Start = (Get-VariableValue $INCOMING_EMAIL "localhost" $useHardcodedDefaults)

    # MANAGED ACCOUNTS
        # CommonNames must match those in the configuration file. They are used in the script as well.
    log "INFO: Setting Managed Accounts variables"
    log "INFO: spservice"
    $managedAccountXML = $xmlinput.Configuration.Farm.ManagedAccounts.ManagedAccount | Where-Object { $_.CommonName -eq "spservice" }
    $username = (Get-VariableValue $SPSERVICE_ACCOUNT "svc_sp_Services" $useHardcodedDefaults)
    $managedAccountXML.Username = "$domain\$username"
    $managedAccountXML.Password = get-serviceAccountPassword -username $username

    log "INFO: portalapppool"
    $managedAccountXML = $xmlinput.Configuration.Farm.ManagedAccounts.ManagedAccount | Where-Object { $_.CommonName -eq "portalapppool" }
    $username = (Get-VariableValue $PORTAL_APPPOOL_ACCOUNT "svc_sp_WebAppPool" $useHardcodedDefaults)
    $managedAccountXML.Username = "$domain\$username"
    $managedAccountXML.Password = get-serviceAccountPassword -username $username

    log "INFO: mysiteapppool"
    $managedAccountXML = $xmlinput.Configuration.Farm.ManagedAccounts.ManagedAccount | Where-Object { $_.CommonName -eq "mysiteapppool" }
    $username = (Get-VariableValue $MYSITES_APPPOOL_ACCOUNT "svc_mysitesapppool" $useHardcodedDefaults)
    $managedAccountXML.Username = "$domain\$username"
    $managedAccountXML.Password = get-serviceAccountPassword -username $username

    log "INFO: searchservice"
    $managedAccountXML = $xmlinput.Configuration.Farm.ManagedAccounts.ManagedAccount | Where-Object { $_.CommonName -eq "searchservice" }
    $username = (Get-VariableValue $SEARCH_SERVICE_ACCOUNT "svc_sp_search" $useHardcodedDefaults)
    $managedAccountXML.Username = "$domain\$username"
    $managedAccountXML.Password = get-serviceAccountPassword -username $username

    log "INFO: Portal"
    $managedAccountXML = $xmlinput.Configuration.Farm.ManagedAccounts.ManagedAccount | Where-Object { $_.CommonName -eq "Portal" }
    $username = (Get-VariableValue $PORTAL_ACCOUNT "svc_sp_farm" $useHardcodedDefaults)
    $managedAccountXML.Username = "$domain\$username"
    $managedAccountXML.Password = get-serviceAccountPassword -username $username

    log "INFO: MySiteHost"
    $managedAccountXML = $xmlinput.Configuration.Farm.ManagedAccounts.ManagedAccount | Where-Object { $_.CommonName -eq "MySiteHost" }
    $username = (Get-VariableValue $MYSITES_ACCOUNT "svc_sp_farm" $useHardcodedDefaults)
    $managedAccountXML.Username = "$domain\$username"
    $managedAccountXML.Password = get-serviceAccountPassword -username $username

    # OBJECT CACHE ACOUNTS
    log "INFO: Setting Object Cache Accounts variables"
    $xmlinput.Configuration.Farm.ObjectCacheAccounts.SuperUser = $domain + "\" + (Get-VariableValue $SUPER_USER "svc_sp_SuperUser" $useHardcodedDefaults)
    $xmlinput.Configuration.Farm.ObjectCacheAccounts.SuperReader = $domain + "\" + (Get-VariableValue $SUPER_READER "svc_sp_SuperReader" $useHardcodedDefaults)

    # LOGGING
    log "INFO: Setting Logging variables"
    $xmlinput.Configuration.Farm.Logging.IISLogs.Path = (Get-VariableValue $IISLOGS_LOCATION "l:\logfiles\iis" $useHardcodedDefaults)
    $xmlinput.Configuration.Farm.Logging.ULSLogs.LogLocation = (Get-VariableValue $ULSLOGS_LOCATION "l:\logfiles\uls" $useHardcodedDefaults)
    $xmlinput.Configuration.Farm.Logging.UsageLogs.UsageLogDir = (Get-VariableValue $USAGELOGS_LOCATION "l:\logfiles\usage" $useHardcodedDefaults)

    # SEARCH - Enterprise Search Instance
    # supported values: false, localhost
    log "INFO: Setting EnterpriseSearchService Instance variables"
    $xmlinput.Configuration.ServiceApps.EnterpriseSearchService.Provision = (Get-VariableValue $ENTSEARCH_PROVISION "localhost" $useHardcodedDefaults)
    $xmlinput.Configuration.ServiceApps.EnterpriseSearchService.ContactEmail = (Get-VariableValue $ENTSEARCH_CONTACTEMAIL "admin" $useHardcodedDefaults) + "@$CLIENT_DOMAIN"
    $xmlinput.Configuration.ServiceApps.EnterpriseSearchService.CustomIndexLocation = (Get-VariableValue $ENTSEARCH_CUSTOMINDEXLOCATION "G:\SP_Index" $useHardcodedDefaults)

    # SEARCH - Enterprise Search Service Application
    # IMPORTANT: xml is catering for multiple search service applications. This cannot be achived by using Agility variables.
    # supported values: server name or blank
    # configuration file caters for multipl search service application. However, it hasn't been tested and Agility doesn't support it.
    log "INFO: Setting EnterpriseSearch Service Application variables"
    $searchServiceApp = $xmlinput.Configuration.ServiceApps.EnterpriseSearchService.EnterpriseSearchServiceApplications.EnterpriseSearchServiceApplication | Select-Object -first 1
    $searchServiceApp.FailoverDatabaseServer = (Get-VariableValue $ENTSEARCH_SVCAPP_FAILOVER_DBNAME "" $useHardcodedDefaults)

    # SEARCH - Enterprise Search Service Application - Content access account
    $username = (Get-VariableValue $ENTSEARCH_SVCAPP_CONTENT_ACCESS_ACCOUNT "svc_sp_Content" $useHardcodedDefaults)
    $searchServiceApp.ContentAccessAccount = "$domain\$username"
    $searchServiceApp.ContentAccessAccountPassword = get-serviceAccountPassword -username $username

    # SEARCH - Enterprise Search Service Application - Search Center
    # TODO ConstructUrl should be changed to cater for path-based URLs as well
    $searchServiceApp.SearchCenterUrl = (ConstructURL $searchServiceApp.SearchCenterUrl "$CLIENT_DOMAIN/pages" $useSSL)

    # SEARCH - Enterprise Search Service Application - database
    $searchDB = (Get-VariableValue $ENTSEARCH_DB_SERVER $sp_db_server $useHardcodedDefaults)
    $searchDB_server = ([string](Get-ServerName $searchDB)).ToUpper()
    $searchServiceApp.Database.DBAlias.DBInstance = $searchDB_server + "\" + (Get-VariableValue $ENTSEARCH_DB_INSTANCE_NAME  "sp_search" $useHardcodedDefaults)
    $searchServiceApp.Database.DBAlias.DBPort = (Get-VariableValue $ENTSEARCH_DB_INSTANCE_PORT "49012" $useHardcodedDefaults)


    # SEARCH - Topology
    # supported values: false, localhost
    $searchServiceApp.CrawlComponent.Provision = (Get-VariableValue $ENTSEARCH_SVCAPP_CRAWLSERVER "localhost" $useHardcodedDefaults)
    $searchServiceApp.QueryComponent.Provision = (Get-VariableValue $ENTSEARCH_SVCAPP_QUERYSERVER "localhost" $useHardcodedDefaults)
    $searchServiceApp.SearchQueryAndSiteSettingsComponent.Provision = (Get-VariableValue $ENTSEARCH_SVCAPP_SEARCHQUERYSETTINGSSERVER "localhost" $useHardcodedDefaults)
    $searchServiceApp.AdminComponent.Provision = (Get-VariableValue $ENTSEARCH_SVCAPP_ADMINSERVER "localhost" $useHardcodedDefaults)
    $searchServiceApp.IndexComponent.Provision = (Get-VariableValue $ENTSEARCH_SVCAPP_INDEXSERVER "localhost" $useHardcodedDefaults)
    $searchServiceApp.ContentProcessingComponent.Provision = (Get-VariableValue $ENTSEARCH_SVCAPP_CONTENTSERVER "localhost" $useHardcodedDefaults)
    $searchServiceApp.AnalyticsProcessingComponent.Provision = (Get-VariableValue $ENTSEARCH_SVCAPP_ANALYTICSSERVER "localhost" $useHardcodedDefaults)

    # MANAGED METADATA SERVICE APP - install on a WFE (recommended by MSFT)
    # supported values: false, localhost
    log "INFO: Setting Managed Metadata variables"
    $xmlinput.Configuration.ServiceApps.ManagedMetadataServiceApp.Provision  = (Get-VariableValue $MM_PROVISION "localhost" $useHardcodedDefaults)
    $mmDB = (Get-VariableValue $MM_DB_SERVER $sp_db_server $useHardcodedDefaults)
    $mmDB_server = ([string](Get-ServerName $mmDB)).ToUpper()
    $xmlinput.Configuration.ServiceApps.ManagedMetadataServiceApp.Database.DBAlias.DBInstance = $mmDB_server + "\" + (Get-VariableValue $MM_DB_INSTANCE_NAME  "sp_svcapps" $useHardcodedDefaults) # TODO: s.b. sp_svcapp_server
    $xmlinput.Configuration.ServiceApps.ManagedMetadataServiceApp.Database.DBAlias.DBPort = (Get-VariableValue $MM_DB_INSTANCE_PORT "49013" $useHardcodedDefaults)

    # WEB APPLICATIONS AND SITE COLLECTIONS
    # IMPORTANT: xml is catering for multiple web applications and multiple site collections. 
    #            This cannot be achived by using Agility variables.
    #            Agility supports 1 Portal web app with root site col and 1 MySites web app with root site col
    #            Use configuration file without Agility variables to support multiple web apps and site colls
    
    log "INFO: Setting Portal Web Applications variables"
    $portalWebApp = $xmlinput.Configuration.WebApplications.WebApplication | Where-Object { $_.type -eq "Portal" }
    $portalWebApp.name = (Get-VariableValue $PORTAL_WEBAPP_NAME "MWS2Portal" $useHardcodedDefaults)

    # check if UseHostHeader = true
    # if yes, assuming it is a proper URL, not server name
    # TODO: UseHostHeader flag really needs to go to the Variables
    log "INFO: if Host Header is used, assume friendly URL, UseHostHeader = $portalWebApp.UseHostHeader, Web URL = $portalWebApp.url"
    if ($portalWebApp.UseHostHeader -eq "false")
    {
        # will be hosting Host Named Site collections
        $portalServer =  ([string](Get-ServerName (Get-VariableValue $PORTAL_WEBAPP_URL "APP-001" $useHardcodedDefaults)))
        $portalWebAppUrl = (ConstructURL $portalServer $CLIENT_DOMAIN $useSSL)
    }
    else
    {        
        $portalWebAppUrl = (ConstructURL (Get-VariableValue $PORTAL_WEBAPP_URL "portal-web-app" $useHardcodedDefaults) $CLIENT_DOMAIN $useSSL)
    }
    
    $portalWebApp.url = $portalWebAppUrl
    $portalWebAppPort = (Get-VariableValue $PORTAL_WEBAPP_PORT "443" $useHardcodedDefaults)
    $portalWebApp.port = $portalWebAppPort

    $portalWebAppDB = (Get-VariableValue $PORTAL_DB_SERVER $sp_db_server $useHardcodedDefaults)
    $portalWebAppDB_server = ([string](Get-ServerName $portalWebAppDB)).ToUpper()
    $portalWebApp.Database.DBAlias.DBInstance = $portalWebAppDB_server + "\" + (Get-VariableValue $PORTAL_DB_INSTANCE "sp_content" $useHardcodedDefaults) # TODO: s.b. sp_content
    $portalWebApp.Database.DBAlias.DBPort = (Get-VariableValue $PORTAL_DB_PORT "49008" $useHardcodedDefaults)

    foreach($siteCol in $portalWebApp.SiteCollections.SiteCollection)
    {
        log "INFO: Setting Site Collections variables $siteCol.siteUrl"
        if ((([string]$siteCol.siteUrl).ToLower() -eq "root") -or (([string]$siteCol.siteUrl).Contains($portalWebAppUrl) -eq $true))
        {
            if (($portalWebAppPort -eq "80") -or ($portalWebAppPort -eq "443"))
            {
                $siteCol.siteUrl = $portalWebAppUrl
            }
            else
            {
                $siteCol.siteUrl = $portalWebAppUrl + ":" + $portalWebAppPort
            }
        }
        else
        {
            # is it host named sit ecollection?
            if ($siteCol.HostNamedSiteCollection -eq "true")
            {
                $siteCol.siteUrl = (ConstructURL $siteCol.siteUrl $CLIENT_DOMAIN  $useSSL)
            }
            else
            {
                if (!(([string] $siteCol.siteUrl).Contains($portalWebAppUrl)))
                {
                    $siteCol.siteUrl = $portalWebAppUrl + $siteCol.siteUrl
                }
            }
        }

        $siteCol.SearchUrl = (ConstructURL $siteCol.SearchUrl "$CLIENT_DOMAIN/pages" $useSSL)
        $siteCol.Owner = $domain + "\" + (Get-VariableValue $SITE_COL_OWNER "agilitydeploy" $useHardcodedDefaults)
    }

    # MY SITES WEB APP
    # MWSR2 - no dedicated My Site web application. This is control via the config xml
    log "INFO: Setting MySites Web Applications variables"
    $myWebApp = $xmlinput.Configuration.WebApplications.WebApplication | Where-Object { $_.type -eq "MySiteHost" }
    if ($myWebApp -ne $null)
    {
        $myWebApp.name = (Get-VariableValue $MYSITES_WEBAPP_NAME "MySites" $useHardcodedDefaults)
        $myWebAppUrl = (ConstructURL (Get-VariableValue $MYSITES_WEBAPP_URL "my" $useHardcodedDefaults) $CLIENT_DOMAIN $useSSL) 
        $myWebApp.url = $myWebAppUrl
        $myWebAppPort = (Get-VariableValue $MYSITES_WEBAPP_PORT "443" $useHardcodedDefaults)
        $myWebApp.port = $myWebAppPort

        $myWebAppDB = (Get-VariableValue $MYSITES_DB_SERVER $sp_db_server $useHardcodedDefaults)
        $myWebAppDB_server = ([string](Get-ServerName $myWebAppDB)).ToUpper()

        $myWebApp.Database.DBAlias.DBInstance = $myWebAppDB_server + "\" + (Get-VariableValue $MYSITES_DB_INSTANCE "sp_config" $useHardcodedDefaults) # TODO: s.b. sp_content
        $myWebApp.Database.DBAlias.DBPort = (Get-VariableValue $MYSITES_DB_PORT "49008" $useHardcodedDefaults)

        $rootSiteColMySites = $myWebApp.SiteCollections.SiteCollection | Select-Object -first 1
        if (($myWebApp.port -eq "80") -or ($myWebApp.port -eq "443"))
        {
            $rootSiteColMySites.siteUrl = $myWebAppUrl
        }
        else
        {
            $rootSiteColMySites.siteUrl = $myWebAppUrl + ":" + $myWebAppPort
        }

        $rootSiteColMySites.SearchUrl = (ConstructURL $rootSiteColMySites.SearchUrl "$CLIENT_DOMAIN/pages" $useSSL)
        $rootSiteColMySites.Owner = $domain + "\" + (Get-VariableValue $MYSITES_COL_OWNER "agilitydeploy" $useHardcodedDefaults)
    }

    # USER PROFILE SERVICE APP is configured using dedicated script
    # USER PROFILE SERVICE APP
    log "INFO: Setting User Profile Service Application variables"
    $xmlinput.Configuration.ServiceApps.UserProfileServiceApp.Provision = (Get-VariableValue $UP_PROVISION "localhost" $useHardcodedDefaults)
    
    $synchServer =  ([string](Get-ServerName (Get-VariableValue $UP_SYNCH_SERVER "APP-001" $useHardcodedDefaults)))
    $xmlinput.Configuration.ServiceApps.UserProfileServiceApp.SynchServer = $synchServer

    $xmlinput.Configuration.ServiceApps.UserProfileServiceApp.StartProfileSync = (Get-VariableValue $UP_STARTPROFILESYNCH "false" $useHardcodedDefaults) 

    $syncConnAcct = (Get-VariableValue $UP_SYNCCONNACCOUNT "svc_sp_farm" $useHardcodedDefaults)
    $xmlinput.Configuration.ServiceApps.UserProfileServiceApp.SyncConnectionAccount = $domain + "\" + $syncConnAcct
    $xmlinput.Configuration.ServiceApps.UserProfileServiceApp.SyncConnectionAccountPassword = (get-serviceAccountPassword -username $syncConnAcct)
    $upDB = (Get-VariableValue $UP_DB_SERVER $sp_db_server $useHardcodedDefaults)
    $upDB_server = ([string](Get-ServerName $upDB)).ToUpper()
    $xmlinput.Configuration.ServiceApps.UserProfileServiceApp.Database.DBAlias.DBInstance = $upDB_server + "\" + (Get-VariableValue $UP_DB_INSTANCE_NAME  "svc_sp_userprofiles" $useHardcodedDefaults)
    $xmlinput.Configuration.ServiceApps.UserProfileServiceApp.Database.DBAlias.DBPort = (Get-VariableValue $UP_DB_INSTANCE_PORT "49013" $useHardcodedDefaults)

    $mySitesCol = $xmlinput.Configuration.ServiceApps.UserProfileServiceApp.MySiteHostLocation
    $xmlinput.Configuration.ServiceApps.UserProfileServiceApp.MySiteHostLocation = (ConstructURL $mySitesCol $CLIENT_DOMAIN  $useSSL)
        
    # STATE SERVICE
    log "INFO: Setting State Service Service Application variables"
    $xmlinput.Configuration.ServiceApps.StateService.Provision = (Get-VariableValue $STATESVC_PROVISION "localhost" $useHardcodedDefaults)
    $db = (Get-VariableValue $STATESVC_DB_SERVER $sp_db_server $useHardcodedDefaults)
    $db_server = ([string](Get-ServerName $db)).ToUpper()
    $xmlinput.Configuration.ServiceApps.StateService.Database.DBAlias.DBInstance = $db_server + "\" + (Get-VariableValue $STATESVC_DB_INSTANCE_NAME  "sp_svcapps" $useHardcodedDefaults) # TODO: s.b. sp_svcapp_server
    $xmlinput.Configuration.ServiceApps.StateService.Database.DBAlias.DBPort = (Get-VariableValue $STATESVC_DB_INSTANCE_PORT "49013" $useHardcodedDefaults)

    # SP USAGE SERVICE
    log "INFO: Setting SPUsageService Service Application variables"
    $xmlinput.Configuration.ServiceApps.SPUsageService.Provision = (Get-VariableValue $SPUSAGE_PROVISION "localhost" $useHardcodedDefaults)
    $db = (Get-VariableValue $SPUSAGE_DB_SERVER $sp_db_server $useHardcodedDefaults)
    $db_server = ([string](Get-ServerName $db)).ToUpper()
    $xmlinput.Configuration.ServiceApps.SPUsageService.Database.DBAlias.DBInstance = $db_server + "\" + (Get-VariableValue $SPUSAGE_DB_INSTANCE_NAME  "sp_svcapps" $useHardcodedDefaults) # TODO: s.b. sp_svcapp_common
    $xmlinput.Configuration.ServiceApps.SPUsageService.Database.DBAlias.DBPort = (Get-VariableValue $SPUSAGE_DB_INSTANCE_PORT "49013" $useHardcodedDefaults)

    # SECURE STORE SERVICE
    log "INFO: Setting SecureStoreService Service Application variables"
    $xmlinput.Configuration.ServiceApps.SecureStoreService.Provision = (Get-VariableValue $SECSTORE_PROVISION "localhost" $useHardcodedDefaults)
    $db = (Get-VariableValue $SECSTORE_DB_SERVER $sp_db_server $useHardcodedDefaults)
    $db_server = ([string](Get-ServerName $db)).ToUpper()
    $xmlinput.Configuration.ServiceApps.SecureStoreService.Database.DBAlias.DBInstance = $db_server + "\" + (Get-VariableValue $SECSTORE_DB_INSTANCE_NAME  "sp_svcapps" $useHardcodedDefaults) # TODO: s.b. sp_securestore
    $xmlinput.Configuration.ServiceApps.SecureStoreService.Database.DBAlias.DBPort = (Get-VariableValue $SECSTORE_DB_INSTANCE_PORT "49013" $useHardcodedDefaults)

    # BUSINESS DATA CONNECTIVITY
    log "INFO: Setting BusinessDataConnectivity Service Application variables"
    $xmlinput.Configuration.ServiceApps.BusinessDataConnectivity.Provision = (Get-VariableValue $BDC_PROVISION "localhost" $useHardcodedDefaults)
    $db = (Get-VariableValue $BDC_DB_SERVER $sp_db_server $useHardcodedDefaults)
    $db_server = ([string](Get-ServerName $db)).ToUpper()
    $xmlinput.Configuration.ServiceApps.BusinessDataConnectivity.Database.DBAlias.DBInstance = $db_server + "\" + (Get-VariableValue $BDC_DB_INSTANCE_NAME  "sp_svcapps" $useHardcodedDefaults) # TODO: s.b. sp_svcapp_common
    $xmlinput.Configuration.ServiceApps.BusinessDataConnectivity.Database.DBAlias.DBPort = (Get-VariableValue $BDC_DB_INSTANCE_PORT "49013" $useHardcodedDefaults)

    # WORD AUTOMATION SERVICE
    log "INFO: Setting WordAutomationService Service Application variables"
    $xmlinput.Configuration.ServiceApps.WordAutomationService.Provision = (Get-VariableValue $WORDAUTO_PROVISION "localhost" $useHardcodedDefaults)
    $db = (Get-VariableValue $WORDAUTO_DB_SERVER $sp_db_server $useHardcodedDefaults)
    $db_server = ([string](Get-ServerName $db)).ToUpper()
    $xmlinput.Configuration.ServiceApps.WordAutomationService.Database.DBAlias.DBInstance = $db_server + "\" + (Get-VariableValue $WORDAUTO_DB_INSTANCE_NAME  "sp_svcapps" $useHardcodedDefaults) # TODO: s.b. sp_svcapp_server
    $xmlinput.Configuration.ServiceApps.WordAutomationService.Database.DBAlias.DBPort = (Get-VariableValue $WORDAUTO_DB_INSTANCE_PORT "49013" $useHardcodedDefaults)

    # APP MANAGEMENT SERVICE
    log "INFO: Setting AppManagementService Service Application variables"
    $xmlinput.Configuration.ServiceApps.AppManagementService.Provision = (Get-VariableValue $APPMGMT_PROVISION "localhost" $useHardcodedDefaults)
    $xmlinput.Configuration.ServiceApps.AppManagementService.AppDomain = (Get-VariableValue $APPMGMT_DOMAIN "app" $useHardcodedDefaults) + ".$CLIENT_DOMAIN"

    $db = (Get-VariableValue $APPMGMT_DB_SERVER $sp_db_server $useHardcodedDefaults)
    $db_server = ([string](Get-ServerName $db)).ToUpper()
    $xmlinput.Configuration.ServiceApps.AppManagementService.Database.DBAlias.DBInstance = $db_server + "\" + (Get-VariableValue $APPMGMT_DB_INSTANCE_NAME  "sp_svcapps" $useHardcodedDefaults) # TODO: s.b. sp_svcapp_common
    $xmlinput.Configuration.ServiceApps.AppManagementService.Database.DBAlias.DBPort = (Get-VariableValue $APPMGMT_DB_INSTANCE_PORT "49013" $useHardcodedDefaults)

    # SUBSCRIPTION SETTINGS SERVICE
    log "INFO: Setting SubscriptionSettingsService Service Application variables"
    $xmlinput.Configuration.ServiceApps.SubscriptionSettingsService.Provision = (Get-VariableValue $SUBSCR_PROVISION "localhost" $useHardcodedDefaults)
    $xmlinput.Configuration.ServiceApps.SubscriptionSettingsService.AppSiteSubscriptionName = (Get-VariableValue $SUBSCR_PROVISION "app" $useHardcodedDefaults)
    $db = (Get-VariableValue $SUBSCR_DB_SERVER $sp_db_server $useHardcodedDefaults)
    $db_server = ([string](Get-ServerName $db)).ToUpper()
    $xmlinput.Configuration.ServiceApps.SubscriptionSettingsService.Database.DBAlias.DBInstance = $db_server + "\" + (Get-VariableValue $SUBSCR_DB_INSTANCE_NAME  "sp_svcapps" $useHardcodedDefaults) # TODO: s.b. sp_svcapp_common
    $xmlinput.Configuration.ServiceApps.SubscriptionSettingsService.Database.DBAlias.DBPort = (Get-VariableValue $SUBSCR_DB_INSTANCE_PORT "49013" $useHardcodedDefaults)

    # WORK MANAGEMENT SERVICE
    log "INFO: Setting WorkManagementService Service Application variables"
    $xmlinput.Configuration.ServiceApps.WorkManagementService.Provision = (Get-VariableValue $WORKMGMT_PROVISION "localhost" $useHardcodedDefaults)

    # MACHINE TRANSLATION SERVICE
    log "INFO: Setting MachineTranslationService Service Application variables"
    $xmlinput.Configuration.ServiceApps.MachineTranslationService.Provision = (Get-VariableValue $TRANSL_PROVISION "localhost" $useHardcodedDefaults)
    $db = (Get-VariableValue $TRANSL_DB_SERVER $sp_db_server $useHardcodedDefaults)
    $db_server = ([string](Get-ServerName $db)).ToUpper()
    $xmlinput.Configuration.ServiceApps.MachineTranslationService.Database.DBAlias.DBInstance = $db_server + "\" + (Get-VariableValue $TRANSL_DB_INSTANCE_NAME  "sp_svcapps" $useHardcodedDefaults) # TODO: s.b. sp_svcapp_server
    $xmlinput.Configuration.ServiceApps.MachineTranslationService.Database.DBAlias.DBPort = (Get-VariableValue $TRANSL_DB_INSTANCE_PORT "49013" $useHardcodedDefaults)

    # POWERPOINT CONVERSION SERVICE
    log "INFO: Setting PowerPointConversionService Service Application variables"
    $xmlinput.Configuration.ServiceApps.PowerPointConversionService.Provision = (Get-VariableValue $PPTCONV_PROVISION "localhost" $useHardcodedDefaults)

    # EXCEL SERVICES
    log "INFO: Setting ExcelServices Service Application variables"
    $xmlinput.Configuration.EnterpriseServiceApps.ExcelServices.Provision = (Get-VariableValue $EXCEL_PROVISION "localhost" $useHardcodedDefaults)
    $unattendedAcct = (Get-VariableValue $EXCEL_ACCT "svc_sp_Excel" $useHardcodedDefaults)
    $xmlinput.Configuration.EnterpriseServiceApps.ExcelServices.UnattendedIDUser = $domain + "\" + $unattendedAcct
    $xmlinput.Configuration.EnterpriseServiceApps.ExcelServices.UnattendedIDPassword = get-serviceAccountPassword -username $unattendedAcct

    # VISIO
    log "INFO: Setting VisioService Service Application variables"
    $xmlinput.Configuration.EnterpriseServiceApps.VisioService.Provision = (Get-VariableValue $VISIO_PROVISION "localhost" $useHardcodedDefaults)
    $unattendedAcct = (Get-VariableValue $VISIO_ACCT "svc_sp_farm" $useHardcodedDefaults)
    $xmlinput.Configuration.EnterpriseServiceApps.VisioService.UnattendedIDUser = $domain + "\" + $unattendedAcct
    $xmlinput.Configuration.EnterpriseServiceApps.VisioService.UnattendedIDPassword = get-serviceAccountPassword -username $unattendedAcct

    # ACCESS 2010
    log "INFO: Setting AccessService Service Application variables"
    $xmlinput.Configuration.EnterpriseServiceApps.AccessService.Provision = (Get-VariableValue $ACCESS2010_PROVISION "localhost" $useHardcodedDefaults)

    # ACCESS SERVICES
    log "INFO: Setting AccessServices Service Application variables"
    $xmlinput.Configuration.EnterpriseServiceApps.AccessServices.Provision = (Get-VariableValue $ACCESS_PROVISION "localhost" $useHardcodedDefaults)
    $db = (Get-VariableValue $ACCESS_DB_SERVER $sp_db_server $useHardcodedDefaults)
    $db_server = ([string](Get-ServerName $db)).ToUpper()
    $xmlinput.Configuration.EnterpriseServiceApps.AccessServices.Database.DBAlias.DBInstance = $db_server + "\" + (Get-VariableValue $ACCESS_DB_INSTANCE_NAME  "sp_svcapps" $useHardcodedDefaults) # TODO: s.b. sp_svcapp_server
    $xmlinput.Configuration.EnterpriseServiceApps.AccessServices.Database.DBAlias.DBPort = (Get-VariableValue $ACCESS_DB_INSTANCE_PORT "49013" $useHardcodedDefaults)

    # PERFORMANCE POINT
    log "INFO: Setting PerformancePointService Service Application variables"
    $xmlinput.Configuration.EnterpriseServiceApps.PerformancePointService.Provision = (Get-VariableValue $PERFPOINT_PROVISION "localhost" $useHardcodedDefaults)
    $unattendedAcct = (Get-VariableValue $PERFPOINT_ACCT "svc_sp_farm" $useHardcodedDefaults)
    $xmlinput.Configuration.EnterpriseServiceApps.PerformancePointService.UnattendedIDUser = $domain + "\" + $unattendedAcct
    $xmlinput.Configuration.EnterpriseServiceApps.PerformancePointService.UnattendedIDPassword = get-serviceAccountPassword -username $unattendedAcct

    $db = (Get-VariableValue $PERFPOINT_DB_SERVER $sp_db_server $useHardcodedDefaults)
    $db_server = ([string](Get-ServerName $db)).ToUpper()
    $xmlinput.Configuration.EnterpriseServiceApps.PerformancePointService.Database.DBAlias.DBInstance = $db_server + "\" + (Get-VariableValue $PERFPOINT_DB_INSTANCE_NAME  "sp_svcapps" $useHardcodedDefaults) # TODO: s.b. sp_svcapp_server
    $xmlinput.Configuration.EnterpriseServiceApps.PerformancePointService.Database.DBAlias.DBPort = (Get-VariableValue $PERFPOINT_DB_INSTANCE_PORT "49013" $useHardcodedDefaults)

    # *** update INPUT xml with the values from variables, like server name, domain, etc
    $xmlinput.Save($inputFile)
}

function CheckForError
{
    # check if error.txt exists. if yes, read it and throw exception
    # This is done to get an error code from the scheduled task.
    $errorFile = "$scriptPath\error.txt"
    if (CheckFileExists($errorFile))
    {
        $error = Get-Content $errorFile
        Remove-Item $errorFile
   
        throw $error
    }
}

############################################################################################
# Main
# Author: Marina Krynina
# Updates: 
#         2014-12-17 Configures SharePoint 2013 Farm based on configuration xml file
############################################################################################

# \USER_PROFILE
#        \Install
#        \Config
#        \InstallMedia
#        \Logs

# Load Common functions
. .\FilesUtility.ps1
. .\VariableUtility.ps1
. .\PlatformUtils.ps1
. .\LaunchProcess.ps1
. .\Construct-URL.ps1

Set-Location -Path $scriptPath 

$msg = "Start SharePoint 2013 farm configuration"
log "INFO: Starting $msg"
log "INFO: Getting variables values or setting defaults if the variables are not populated."

# *** Determine if we need to use Agility variables or configuration file
$USE_VARIABLES = (Get-VariableValue $USE_VARIABLES $false $true)    

# Client domain. If empty, do not create public URL
$CLIENT_DOMAIN = (Get-VariableValue $CLIENT_DOMAIN "" $true)

# *** configuration input file
$CONFIG_XML = (Get-VariableValue $CONFIG_XML "MWS2_SPFarm.xml" $true)    
$inputFile = "$scriptPath\Config\$config_xml"

# *** setup account 
$domain = get-domainshortname
$domainFull = get-domainname
$user = (Get-VariableValue $ADMIN "agilitydeploy" $true)
$password = get-serviceAccountPassword -username $user
    
# *** Use SSL flag
# using custom code to configure SSL, not autoSPInstaller
$useSSL = (Get-VariableValue $USE_SSL "true" $true)    

# if Agility variables are not populated, the values will be taken directly from the $CONFIG_XML
if ($USE_VARIABLES -eq $true)
{ 
    UpdateInputFile $inputFile
}

# *** Configure SharePoint farm
$process = "$PSHOME\powershell.exe"
try
{
    #################################################################################################################
    # Farm Configuration
    #################################################################################################################
    $argument = "-file $scriptPath\Config\Configure-SharePoint2013.ps1 -scriptPath $scriptPath -inputFile $inputFile -useSSL $useSSL -clientDomain $CLIENT_DOMAIN ; exit `$LastExitCode"
    log "INFO: Calling $process under identity $domain\$user"
    log "INFO: Arguments $argument"

    # It is assumed the SSL certificates have been imported in the separate script
    $Result = LaunchProcessWithHighestPrivAsUser $process $argument "$domain\$user" $password

    # DEBUG
    # . .\Config\Configure-SharePoint2013.ps1 $scriptPath $inputFile
    
    CheckForError

    #################################################################################################################
    # User Profiles COnfiguration
    #################################################################################################################
    # there is no need to check if UP needs to be provisioned as it will be taken care of late in the config script
    $argument = "-file $scriptPath\Config\Configure-UserProfiles.ps1 -scriptPath $scriptPath -inputFile $inputFile -useSSL $useSSL; exit `$LastExitCode"
    log "INFO: Calling $process under identity $domain\$farmAccount"
    log "INFO: Arguments $argument"

    # Create UPSA under farm account. Otherwise it doesn't work
    $farmAccount = $FARM_ACCOUNT
    $farmPassword = (get-serviceAccountPassword -username $FARM_ACCOUNT)      
    
    $Result = LaunchProcessWithHighestPrivAsUser $process $argument "$domain\$farmAccount" $farmPassword

    # DEBUG
    # . .\Config\Configure-UserProfiles.ps1 $scriptPath $inputFile
    
    CheckForError
	
    log "INFO: Finished $msg."
    return 0
}
catch
{
    throw "ERROR: $($_.Exception.Message)"
}
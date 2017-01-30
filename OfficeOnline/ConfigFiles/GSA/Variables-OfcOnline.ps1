$ADMIN = "agilitydeploy"
$USE_SSL = "true" 

#region Configure Product
$PRIMARY_SERVER = "OWA-01"
$EDITING_ENABLED = "false"
$SSLOFFLOADED = "true"

# IMPORTANT: the certificate friendly name. This must match the CERTS_XML.xml 
# It must exists in the Personal store. Otherwise, configuration will fail
$CERTIFICATE_NAME = “MWS OfficeOnline”
$EXTERNAL_URL = ""
$INTERNAL_URL = "OfficeOnline.mwsaust.net"

$CONFIG_XML = "ConfigFiles\OfcOnline_FarmConfig.xml" 
$officeOnlineData = "E:\ProgramData\Microsoft\OfficeWebApps"
$CACHE_LOCATION = "$officeOnlineData\Working\d\"
$LOG_LOCATION = "$officeOnlineData\Data\Logs\ULS\"
$RENDERING_CACHE_LOCATION = "$officeOnlineData\Working\waccache"
#endregion

#region Install Product
$INSTALL_MEDIA = "InstallMedia"
$INSTALLLOCATION = "E:\Program Files\Microsoft OfficeOnline"
$PIDKEY = "P7NC4-K3X6B-D9VP7-YJKPM-X4TMJ"
$SILENTINSTALL_XML = "ConfigFiles\OfcOnline_SilentConfig.xml"
#endregion

#region Install Update
$UPDATES_LOCATION = "InstallMedia\Updates"
$UPDATES_XML = "ConfigFiles\OfcOnline_Updates.xml"
#endregion

$NON_AGILITY = $false
if ($NON_AGILITY)
{
    $COMMONBASESETTINGS_XML = "\ConfigFiles\OfcOnline-CommonBaseSettings.xml"
    $COMPONENTID = ""
    $INSTANCEID = ""
    $PREREQSCONFIG_XML = "\ConfigFiles\OfcOnline-PreRequisites.xml"
    $CERTS_XML = "ConfigFiles\OfcOnline-Certificates.xml"
    $SOURCE = "OfficeOnline"
    $TESTFRAMEWORKFOLDER = "TestFramework"
    $TESTSCRIPTS = "UnitTest-Server-Common.ps1;UnitTest-Server-Common-IIS.ps1;UnitTest-Server-OfficeOnline.ps1"
    $WINDOWSFEATUREXMLFILENAME = "ConfigFiles\OfcOnline-WindowsFeatures.xml"
    $WINDOWSUSERS_XML = "ConfigFiles\OfcOnline-WindowsUsers.xml"
}

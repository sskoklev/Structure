# get current script location
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$scriptName = $MyInvocation.MyCommand.Name

. .\LoggingV2.ps1 $true $scriptPath $scriptName

$USER = 'agilitydeploy'
$SQLINSTALLCONFIG_XML = 'install\SQL2012SP2Ent_SHARED_Secondary.xml'
$MWSREGISTRYXMLFILENAME = 'install\MWSRegistry.xml'
$GENERICSERVICEXMLFILE = 'install\ClusterServices_SharedDB.xml'

$SVC_SQL= 'svc_sql'

. .\Install\Install-SQL2012.ps1